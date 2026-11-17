# frozen_string_literal: true

require "rails_helper"

describe "backstage uploads" do
  before do
    host! "www.livemusiclocator.com.au"

    @admin = create(:lml_user, :admin)
    @other = create(:lml_user, :admin)
    sign_in @admin

    @tote = create(:lml_venue, name: "The Tote", time_zone: "Australia/Melbourne")
    @mine = Lml::Upload.create!(user: @admin, source: "research-markryall", venue: @tote, format: "clipper",
                                time_zone: "Australia/Melbourne", content: "name: Mine\ndate: 2026-12-04\n")
    @theirs = Lml::Upload.create!(user: @other, source: "lmb", venue: @tote, format: "clipper",
                                  time_zone: "Australia/Melbourne", content: "name: Theirs\ndate: 2026-12-05\n")
  end

  it "turns away somebody who is not an admin" do
    sign_in create(:lml_user)

    get "/backstage/uploads"

    expect(response).to redirect_to("/backstage")
  end

  describe "the list" do
    it "starts from your own uploads" do
      get "/backstage/uploads"

      expect(response.body).to include(%(href="/backstage/uploads/#{@mine.id}"))
      expect(response.body).not_to include(%(href="/backstage/uploads/#{@theirs.id}"))
    end

    it "shows everybody's when asked" do
      get "/backstage/uploads", params: { who: "everyone" }

      expect(response.body).to include(%(href="/backstage/uploads/#{@theirs.id}"))
    end

    it "narrows to one source" do
      get "/backstage/uploads", params: { who: "everyone", source: "lmb" }

      expect(response.body).to include(%(href="/backstage/uploads/#{@theirs.id}"))
      expect(response.body).not_to include(%(href="/backstage/uploads/#{@mine.id}"))
    end
  end

  it "offers the content back with gig ids, to send next time" do
    post "/backstage/uploads", params: { upload: { content: "name: Gut Health\ndate: 2026-12-04\n", source: "backstage", venue_id: @tote.id } }

    gig = Lml::Gig.find_by!(name: "Gut Health")
    follow_redirect!
    expect(response.body).to include("To send again")
    expect(response.body).to include("id: #{gig.id}")
  end

  it "shows what an upload sent" do
    get "/backstage/uploads/#{@theirs.id}"

    expect(response.body).to include("name: Theirs")
  end

  describe "making one" do
    def upload(content, **rest)
      post "/backstage/uploads", params: { upload: { content: content, source: "backstage", venue_id: @tote.id }.merge(rest) }
    end

    it "processes it, records who made it, and shows what it did" do
      expect { upload("name: Gut Health\ndate: 2026-12-04\ntime: 20:00\n") }.to change(Lml::Gig, :count).by(1)

      made = Lml::Upload.order(:created_at).last
      expect(made.user).to eq(@admin)
      expect(made.status).to eq("Succeeded")
      expect(Lml::Gig.find_by!(name: "Gut Health").upload).to eq(made)
      expect(response).to redirect_to("/backstage/uploads/#{made.id}")
    end

    it "says why an upload failed" do
      upload("date: 2026-12-04\n")

      made = Lml::Upload.order(:created_at).last
      expect(made.status).to eq("Failed")
      expect(flash[:alert]).to include("The upload failed")
    end

    it "refuses nothing at all" do
      expect { upload("") }.not_to change(Lml::Upload, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    # Processing happens inside the request, and a big one outruns Heroku's
    # router timeout.
    it "refuses more than it can process inside a request" do
      big = Array.new(Lml::Upload::PROCESSING_LIMIT + 1) { |i| "name: Gig #{i}\ndate: 2026-12-04\n" }.join("---\n")

      expect { upload(big) }.not_to change(Lml::Upload, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("the limit is #{Lml::Upload::PROCESSING_LIMIT}")
    end
  end
end
