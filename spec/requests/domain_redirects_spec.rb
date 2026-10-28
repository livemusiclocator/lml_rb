# frozen_string_literal: true

require "rails_helper"

describe "domain redirects" do
  describe "on the bare livemusiclocator.com.au" do
    before { host! "livemusiclocator.com.au" }

    it "sends the home page to www" do
      get "/"

      expect(response).to redirect_to("http://www.livemusiclocator.com.au/")
      expect(response).to have_http_status(:moved_permanently)
    end

    # Only the home page used to redirect, so anybody typing the address
    # without www - backstage included - got a 404.
    it "sends any other page to the same page on www" do
      get "/backstage/login", params: { from: "email" }

      expect(response).to redirect_to("http://www.livemusiclocator.com.au/backstage/login?from=email")
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
