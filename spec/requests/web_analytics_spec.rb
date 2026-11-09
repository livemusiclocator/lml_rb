# frozen_string_literal: true

require "rails_helper"

describe "web layout Google Analytics tag" do
  before do
    allow(SpaAssets).to receive(:refresh_due?).and_return(false)
    host! "www.livemusiclocator.com.au"
    Web::ExplorerConfig.find_by(edition_id: "main") || Web::ExplorerConfig.create!(
      edition_id: "main",
      allow_all_locations: true,
      selectable_locations: ["melbourne"],
      default_location: "melbourne",
    )
  end

  context "when using default test environment" do
    it "does not render the Google Analytics tag on /about" do
      get "/about"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("googletagmanager.com/gtag/js")
      expect(response.body).not_to include("G-8TKSCK99CN")
    end

    it "does not render the Google Analytics tag on /" do
      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("googletagmanager.com/gtag/js")
      expect(response.body).not_to include("G-8TKSCK99CN")
    end
  end

  context "when analytics is enabled" do
    it "renders the official GA4 snippet with G-8TKSCK99CN in the <head>" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)

      get "/about"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=G-8TKSCK99CN")
      expect(response.body).not_to include("gtag('set', { debug_mode: true });")
      expect(response.body).to include("gtag('config', 'G-8TKSCK99CN');")
    end

    it "renders the official GA4 snippet on the root page (/)" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)

      get "/"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=G-8TKSCK99CN")
      expect(response.body).not_to include("gtag('set', { debug_mode: true });")
      expect(response.body).to include("gtag('config', 'G-8TKSCK99CN');")
    end

    it "respects GA_MEASUREMENT_ID environment override when enabled" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)
      stub_const("ENV", ENV.to_h.merge("GA_MEASUREMENT_ID" => "G-CUSTOM999"))

      get "/about"

      expect(response.body).to include("googletagmanager.com/gtag/js?id=G-CUSTOM999")
      expect(response.body).to include("gtag('config', 'G-CUSTOM999');")
    end
  end

  context "when in development environment" do
    before do
      allow(Rails.env).to receive_messages(test?: false, production?: false, development?: true)
    end

    it "renders the dedicated dev tag with debug_mode when ENABLE_ANALYTICS is 'true'" do
      stub_const("ENV", ENV.to_h.merge("ENABLE_ANALYTICS" => "true", "GA_MEASUREMENT_ID" => nil))

      get "/about"

      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=G-Y3W30VYBWV")
      expect(response.body).to include("gtag('set', { debug_mode: true });")
      expect(response.body).to include("gtag('config', 'G-Y3W30VYBWV', { debug_mode: true });")
    end

    it "renders the dedicated dev tag with debug_mode on the root page (/)" do
      stub_const("ENV", ENV.to_h.merge("ENABLE_ANALYTICS" => "true", "GA_MEASUREMENT_ID" => nil))

      get "/"

      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=G-Y3W30VYBWV")
      expect(response.body).to include("gtag('set', { debug_mode: true });")
      expect(response.body).to include("gtag('config', 'G-Y3W30VYBWV', { debug_mode: true });")
    end

    it "respects custom GA_MEASUREMENT_ID override in development while keeping debug_mode" do
      stub_const("ENV", ENV.to_h.merge("ENABLE_ANALYTICS" => "true", "GA_MEASUREMENT_ID" => "G-CUSTOM999"))

      get "/about"

      expect(response.body).to include("https://www.googletagmanager.com/gtag/js?id=G-CUSTOM999")
      expect(response.body).to include("gtag('set', { debug_mode: true });")
      expect(response.body).to include("gtag('config', 'G-CUSTOM999', { debug_mode: true });")
    end

    it "does not render the tag when ENABLE_ANALYTICS is 'false'" do
      stub_const("ENV", ENV.to_h.merge("ENABLE_ANALYTICS" => "false"))

      get "/about"

      expect(response.body).not_to include("googletagmanager.com/gtag/js")
    end

    it "does not render the tag when only GA_MEASUREMENT_ID is present" do
      stub_const("ENV", ENV.to_h.merge("GA_MEASUREMENT_ID" => "G-CUSTOM999", "ENABLE_ANALYTICS" => nil))

      get "/about"

      expect(response.body).not_to include("googletagmanager.com/gtag/js")
    end
  end
end
