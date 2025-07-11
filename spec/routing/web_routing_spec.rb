# frozen_string_literal: true

require "rails_helper"
shared_examples "shared endpoints" do |root_url|
  it "routes #{root_url}/up to healthcheck" do
    expect(get("#{root_url}/up")).to route_to(controller: "rails/health", action: "show")
  end
end
shared_examples "API endpoints" do |root_url|
  describe "API routes at #{root_url}" do
    it "routes #{root_url}/gigs to gigs#index" do
      expect(get("#{root_url}/gigs")).to route_to(controller: "gigs", action: "index", format: "json")
    end
    it "routes #{root_url}/gigs/ABCDEF to gigs#show" do
      expect(get("#{root_url}/gigs/ABCDEF")).to route_to(controller: "gigs", action: "show", id: "ABCDEF",
                                                         format: "json",)
    end
    it "routes #{root_url}/gigs/query to gigs#query" do
      expect(get("#{root_url}/gigs/query")).to route_to(controller: "gigs", action: "query", format: "json")
    end
  end
end

shared_examples "Web endpoints" do |root_url, **additional_params|
  describe "Web routes at #{root_url}" do
    it "routes #{root_url} to explorer#index" do
      expect(get(root_url)).to route_to(controller: "web/explorer", action: "index", **additional_params)
    end
    it "routes #{root_url}/gigs/ABCDEF to explorer#show" do
      expect(get("#{root_url}/gigs/ABCDEF")).to route_to(controller: "web/explorer", action: "show", id: "ABCDEF",
                                                         **additional_params,)
    end
    it "routes #{root_url}/events to explorer#index" do
      expect(get("#{root_url}/events")).to route_to(controller: "web/explorer", action: "index", **additional_params)
    end
    it "routes #{root_url}/about to pages#show for about page" do
      expect(get("#{root_url}/about")).to route_to(controller: "web/pages", action: "show", id: "about",
                                                   **additional_params,)
    end
    it "routes #{root_url}/about/ABCDE to pages#show for ABCDE page" do
      expect(get("#{root_url}/about/ABCDE")).to route_to(controller: "web/pages", action: "show", id: "ABCDE",
                                                         **additional_params,)
    end
  end
end

shared_examples "Admin endpoints" do |root_url|
  describe "Admin routes at #{root_url}" do
    it "routes #{root_url}/ to admin dashboard" do
      expect(get(root_url)).to route_to(controller: "admin/dashboard", action: "index")
    end
    it "routes #{root_url}/login to admin login" do
      expect(get("#{root_url}/login")).to route_to(controller: "active_admin/devise/sessions", action: "new")
    end
  end
end
shared_examples "No web endpoints" do |root_url|
  describe "Web routes at #{root_url}  (disabled)" do
    it "does not route #{root_url}/about to anywhere" do
      expect(get("#{root_url}/about")).to_not route_to(controller: "web/pages", action: "show", id: "about")
    end
  end
end
shared_examples "No admin endpoints" do |root_url|
  describe "Admin routes at #{root_url}  (disabled)" do
    it "does not route #{root_url} to anywhere" do
      expect(get(root_url)).to_not route_to(controller: "admin/dashboard", action: "index")
    end
  end
end

describe "routes" do
  # also testing variable tld lengths work in our setup
  describe "local dev style routes" do
    include_examples "shared endpoints", "https://www.lml.local"
    include_examples "API endpoints", "https://api.lml.local"
    include_examples "Web endpoints", "https://www.lml.local"
  end
  describe "beta.livemusiclocator.com.au routes" do
    include_examples "shared endpoints", "https://beta.livemusiclocator.com.au"

    include_examples "API endpoints", "https://beta.livemusiclocator.com.au/api"
    include_examples "Web endpoints", "https://beta.livemusiclocator.com.au"
    include_examples "Web endpoints", "https://beta.livemusiclocator.com.au/editions/stkilda", edition_id: "stkilda"
    include_examples "No admin endpoints", "https://beta.livemusiclocator.com.au/admin"
  end
  describe "www.livemusiclocator.com.au routes" do
    include_examples "shared endpoints", "https://www.livemusiclocator.com.au"

    include_examples "API endpoints", "https://www.livemusiclocator.com.au/api"
    include_examples "Web endpoints", "https://www.livemusiclocator.com.au"
    include_examples "Web endpoints", "https://www.livemusiclocator.com.au/editions/stkilda", edition_id: "stkilda"
    include_examples "No admin endpoints", "https://www.livemusiclocator.com.au/admin"
  end
  describe "api.lml.live routes" do
    include_examples "shared endpoints", "https://api.lml.live"
    include_examples "API endpoints", "https://api.lml.live"
    include_examples "Admin endpoints", "https://api.lml.live/admin"
    include_examples "No web endpoints", "https://api.lml.live/"
  end
end
