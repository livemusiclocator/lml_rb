# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
require "rails_helper"
shared_examples "www redirects" do |root_url, www_url|
  describe "www redirects at #{root_url} to #{www_url}" do
    it "routes #{root_url} to www url #{www_url}" do
      pending("configuration to test www redirects")
      # TODO: redirect_to is not the right matcher here, but what is ?
      expect(get(root_url.to_s)).to route_to(www_url.to_s)
    end

    it "routes #{root_url}/subpath to www url #{www_url}/subpath" do
      pending("configuration to test www redirects")
      expect(get(root_url.to_s)).to route_to("#{www_url}/subpath")
    end
  end
end

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

    it "routes #{root_url}/events to pages#show for about page" do
      expect(get("#{root_url}/events")).to route_to(controller: "web/pages", action: "show", section: "events",
                                                    id: "events", **additional_params,)
    end

    it "routes #{root_url}/about to pages#show for about page" do
      expect(get("#{root_url}/about")).to route_to(controller: "web/pages", action: "show",
                                                   id: "about", section: "about",
                                                   **additional_params,)
    end

    it "routes #{root_url}/about/ABCDE to pages#show for ABCDE page" do
      expect(get("#{root_url}/about/ABCDE")).to route_to(controller: "web/pages", action: "show",
                                                         id: "ABCDE", section: "about",
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
  describe "Web routes at #{root_url} (disabled)" do
    it "does not route #{root_url}/about to anywhere" do
      expect(get("#{root_url}/about")).not_to route_to(controller: "web/pages", action: "show", id: "about")
    end
  end
end

shared_examples "No admin endpoints" do |root_url|
  describe "Admin routes at #{root_url} (disabled)" do
    it "does not route #{root_url} to anywhere" do
      expect(get(root_url)).not_to route_to(controller: "admin/dashboard", action: "index")
    end
  end
end

describe "routes" do
  # also testing variable tld lengths work in our setup
  describe "local dev style routes" do
    it_behaves_like "shared endpoints", "https://www.livemusiclocator.com.test"
    it_behaves_like "API endpoints", "https://api.lml.local"
    it_behaves_like "Web endpoints", "https://www.livemusiclocator.com.test"
  end

  describe "beta.livemusiclocator.com.au routes" do
    it_behaves_like "shared endpoints", "https://beta.livemusiclocator.com.au"

    it_behaves_like "API endpoints", "https://beta.livemusiclocator.com.au/api"
    it_behaves_like "Web endpoints", "https://beta.livemusiclocator.com.au"
    it_behaves_like "Web endpoints", "https://beta.livemusiclocator.com.au/editions/stkilda", edition_id: "stkilda"
    it_behaves_like "No admin endpoints", "https://beta.livemusiclocator.com.au/admin"
  end

  describe "www.livemusiclocator.com.au routes" do
    it_behaves_like "shared endpoints", "https://www.livemusiclocator.com.au"

    it_behaves_like "API endpoints", "https://www.livemusiclocator.com.au/api"
    it_behaves_like "Web endpoints", "https://www.livemusiclocator.com.au"
    it_behaves_like "Web endpoints", "https://www.livemusiclocator.com.au/editions/stkilda", edition_id: "stkilda"
    it_behaves_like "No admin endpoints", "https://www.livemusiclocator.com.au/admin"
    it_behaves_like "www redirects", "https://www.livemusiclocator.com.au/", "https://www.livemusiclocator.com.au/"
  end

  describe "api.lml.live routes" do
    it_behaves_like "shared endpoints", "https://api.lml.live"
    it_behaves_like "API endpoints", "https://api.lml.live"
    it_behaves_like "Admin endpoints", "https://api.lml.live/admin"
    it_behaves_like "No web endpoints", "https://api.lml.live/"
  end
end
# rubocop:enable Metrics/BlockLength
