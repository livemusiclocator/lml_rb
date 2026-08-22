# frozen_string_literal: true

require "rails_helper"

describe "backstage api tokens" do
  before do
    host! "www.livemusiclocator.com.au"

    @admin = create(:lml_user, :admin)
    @punter = create(:lml_user)
  end

  describe "without an admin" do
    it "refuses a signed out visitor" do
      get "/backstage/api_tokens"

      expect(response).to redirect_to("/backstage/login")
    end

    it "turns a plain backstage user away" do
      sign_in @punter

      get "/backstage/api_tokens"

      expect(response).to redirect_to("/backstage")
    end

    it "refuses to issue a token for a plain backstage user" do
      sign_in @punter

      expect { post "/backstage/api_tokens", params: { name: "Sneaky" } }
        .not_to change(Lml::ApiToken, :count)
    end
  end

  describe "as an admin" do
    before { sign_in @admin }

    it "shows the real secret once, on the response that issued it" do
      post "/backstage/api_tokens", params: { name: "Import script" }

      secret = response.body[/lml_admin_[A-Za-z0-9_-]+/]
      expect(Lml::ApiToken.last.token_digest).to eq(Lml::ApiToken.digest(secret))
    end

    it "does not show the secret again on the next visit" do
      post "/backstage/api_tokens", params: { name: "Import script" }
      secret = response.body[/lml_admin_[A-Za-z0-9_-]+/]

      get "/backstage/api_tokens"

      expect(response.body).not_to include(secret)
    end

    it "records the token against the admin who issued it" do
      post "/backstage/api_tokens", params: { name: "Import script" }

      expect(Lml::ApiToken.last.user).to eq(@admin)
    end

    it "issues a token with no expiry by default" do
      post "/backstage/api_tokens", params: { name: "Import script" }

      expect(Lml::ApiToken.last.expires_at).to be_nil
    end

    it "applies an expiry when one is chosen" do
      post "/backstage/api_tokens", params: { name: "Import script", expires_in_days: "90" }

      expect(Lml::ApiToken.last.expires_at).to be_within(1.minute).of(90.days.from_now)
    end

    it "ignores an expiry we did not offer rather than trusting the number" do
      post "/backstage/api_tokens", params: { name: "Import script", expires_in_days: "99999" }

      expect(Lml::ApiToken.last.expires_at).to be_nil
    end

    it "refuses a token with no name" do
      post "/backstage/api_tokens", params: { name: "  " }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "revokes a token" do
      token = Lml::ApiToken.issue!(user: @admin, name: "Import script")

      delete "/backstage/api_tokens/#{token.id}"

      expect(token.reload).to be_revoked
    end

    it "lists only its owner's tokens" do
      mine = Lml::ApiToken.issue!(user: @admin, name: "Mine")
      theirs = Lml::ApiToken.issue!(user: create(:lml_user, :admin), name: "Somebody Elses")

      get "/backstage/api_tokens"

      expect(response.body).to include(mine.name)
      expect(response.body).not_to include(theirs.name)
    end

    it "leaves somebody else's token alone" do
      theirs = Lml::ApiToken.issue!(user: create(:lml_user, :admin), name: "Somebody Elses")

      delete "/backstage/api_tokens/#{theirs.id}"

      expect(theirs.reload).not_to be_revoked
    end
  end
end
