# frozen_string_literal: true

require "rails_helper"

describe "admin venue import" do
  before do
    host! "api.lml.live"

    @admin_user = Lml::AdminUser.create!(
      email: "venue_import_spec@example.com",
      username: "importer",
      password: "supersecret123",
      password_confirmation: "supersecret123",
      time_zone: "Australia/Melbourne",
    )
    @url = "https://docs.google.com/spreadsheets/d/abc123DEF/edit"
  end

  describe "without an admin session" do
    it "refuses the page" do
      get "/admin/venue_import"

      expect(response).to redirect_to("/admin/login")
    end

    it "refuses to run an import" do
      expect(Lml::VenueImport).not_to receive(:call)

      post "/admin/venue_import/run", params: { sheet_url: @url }

      expect(response).to redirect_to("/admin/login")
    end
  end

  describe "with an admin session" do
    before { sign_in @admin_user, scope: :admin_user }

    it "renders the page" do
      get "/admin/venue_import"

      expect(response).to have_http_status(:ok)
    end

    it "tells you which address to share the sheet with" do
      allow(Lml::Sheet).to receive(:service_account_email).and_return("importer@lml.iam.gserviceaccount.com")

      get "/admin/venue_import"

      expect(response.body).to include("importer@lml.iam.gserviceaccount.com")
    end

    it "says so when the credentials are not configured, rather than failing later" do
      allow(Lml::Sheet).to receive(:service_account_email).and_return(nil)

      get "/admin/venue_import"

      expect(response.body).to include("GOOGLE_SHEETS_SERVICE_ACCOUNT_CREDENTIALS is not set")
    end

    it "runs the import for the url it was given" do
      expect(Lml::VenueImport).to receive(:call).with(@url).and_return({ "created" => 2 })

      post "/admin/venue_import/run", params: { sheet_url: @url }

      expect(response).to redirect_to(%r{/admin/venue_import})
    end

    it "reports what the import did" do
      allow(Lml::VenueImport).to receive(:call).and_return({ "created" => 2, "ambiguous" => 1 })

      post "/admin/venue_import/run", params: { sheet_url: @url }

      expect(flash[:notice]).to eq("Imported: 2 created, 1 ambiguous.")
    end

    it "keeps the url in the form after a run, so a re-run is one click" do
      allow(Lml::VenueImport).to receive(:call).and_return({ "created" => 1 })

      post "/admin/venue_import/run", params: { sheet_url: @url }

      expect(response).to redirect_to(a_string_including(CGI.escape(@url)))
    end

    it "asks for a url rather than calling the importer with nothing" do
      expect(Lml::VenueImport).not_to receive(:call)

      post "/admin/venue_import/run", params: { sheet_url: "  " }

      expect(flash[:alert]).to include("Paste the spreadsheet's URL first")
    end

    it "explains a url that is not a google sheet" do
      allow(Lml::VenueImport).to receive(:call).and_raise(Lml::Sheet::InvalidUrlError)

      post "/admin/venue_import/run", params: { sheet_url: "https://example.com/nope" }

      expect(flash[:alert]).to include("not a Google Sheets URL")
    end

    it "puts the reason on screen when google refuses, rather than a 500" do
      allow(Lml::VenueImport).to receive(:call).and_raise(StandardError, "The caller does not have permission")

      post "/admin/venue_import/run", params: { sheet_url: @url }

      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to include("The caller does not have permission")
    end
  end

  describe "the menu" do
    before { sign_in @admin_user, scope: :admin_user }

    it "does not list the page, which is reached by knowing the url" do
      get "/admin/dashboard"

      expect(response.body).not_to include("Venue Import")
    end
  end
end
