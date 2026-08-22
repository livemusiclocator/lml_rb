# frozen_string_literal: true

require "rails_helper"

# Every route under the admin API, read off the route table rather than a hand
# written list, so a new endpoint added without authentication fails the build
# instead of shipping.
module AdminApiRoutes
  ANY_ID = "00000000-0000-0000-0000-000000000000"

  def self.all
    Rails.application.routes.routes.filter_map do |route|
      path = route.path.spec.to_s.sub("(.:format)", "")
      next unless path.start_with?("/v1/admin")

      { verb: route.verb.downcase.to_sym, path: path.gsub(/:[a-z_]+/, ANY_ID) }
    end
  end
end

describe "admin api authentication" do
  before do
    host! "api.lml.live"

    @admin = create(:lml_user, :admin)
    @token = Lml::ApiToken.issue!(user: @admin, name: "Import script")
    @secret = @token.plaintext
  end

  it "found some routes to check, so an empty sweep cannot pass for a clean one" do
    expect(AdminApiRoutes.all.length).to be >= 8
  end

  AdminApiRoutes.all.each do |route|
    describe "#{route[:verb].upcase} #{route[:path]}" do
      it "refuses a caller with no token" do
        public_send(route[:verb], route[:path])

        expect(response).to have_http_status(:unauthorized)
      end

      it "refuses a caller with a token we never issued" do
        public_send(route[:verb], route[:path], headers: { "Authorization" => "Bearer lml_admin_guessed" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "refuses a caller with a revoked token" do
        @token.revoke!

        public_send(route[:verb], route[:path], headers: { "Authorization" => "Bearer #{@secret}" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "refuses a token whose owner is no longer an admin" do
        @admin.update!(admin: false)

        public_send(route[:verb], route[:path], headers: { "Authorization" => "Bearer #{@secret}" })

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "how a token may be presented" do
    it "refuses a token in the query string, which is how tokens end up in logs" do
      get "/v1/admin/acts", params: { token: @secret }

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses an expired token" do
      @token.update!(expires_at: 1.minute.ago)

      get "/v1/admin/acts", headers: { "Authorization" => "Bearer #{@secret}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuses the token without the Bearer scheme" do
      get "/v1/admin/acts", headers: { "Authorization" => @secret }

      expect(response).to have_http_status(:unauthorized)
    end

    it "says how to authenticate when it refuses" do
      get "/v1/admin/acts"

      expect(response.headers["WWW-Authenticate"]).to include("Bearer")
    end

    it "accepts a valid bearer token" do
      get "/v1/admin/acts", headers: { "Authorization" => "Bearer #{@secret}" }

      expect(response).to have_http_status(:ok)
    end

    it "records that the token was used" do
      get "/v1/admin/acts", headers: { "Authorization" => "Bearer #{@secret}" }

      expect(@token.reload.last_used_at).to be_present
    end

    it "cannot be reached with an admin session cookie instead of a token" do
      sign_in @admin

      get "/v1/admin/acts"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
