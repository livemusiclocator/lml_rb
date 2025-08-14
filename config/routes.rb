# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  # all the routes making up the main parts of the api
  concern :the_api do
    root to: "gigs#index", defaults: { format: "json" }
    get "query", to: "gigs#query", defaults: { format: "json" }
    get ":id", to: "gigs#show", defaults: { format: "json" }
  end

  # all the routes providing the standard front end
  concern :gig_guide do
    root to: "explorer#index", as: :web_root
    scope "gigs" do
      get ":id", to: "explorer#show"
    end
    get "/events", to: "pages#show", id: "events", section: "events", as: :web_events_page
    get "/about", to: "pages#show", id: "about", section: "about", as: :web_about_page
    get "/about/*id", to: "pages#show", section: "about", as: :web_about_section_page
  end

  # Debug route for development - shows how Rails parses domains/subdomains
  if Rails.env.development?
    get "debug_domain", to: lambda { |env|
      request = ActionDispatch::Request.new(env)
      [200, { "Content-Type" => "text/plain" }, [
        "Host: #{request.host}\n" \
        "Domain: #{request.domain.inspect}\n" \
        "Subdomain: #{request.subdomain.inspect}\n" \
        "Subdomains: #{request.subdomains.inspect}\n" \
        "Port: #{request.port}\n" \
        "Full URL: #{request.url}\n",
      ],]
    }
  end
  # shared routes - no subdomain constraints
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # www.livemusiclocator.com.au and beta.livemusiclocator.com.au
  # (also probably www.lml.live and beta.lml.live if we set these up)
  # Match only routes to the subdomain 'beta' and 'www'
  # (lax matching due to tld_length issues described in introducing commit notes)
  constraints subdomain: /^(beta|www)(\.\w+)?/ do
    # mount the lml api handlers here
    scope "api/gigs", as: "web_api" do
      concerns :the_api
    end
    # sitemap

    scope module: "web" do
      get "/sitemap.xml", to: "meta#show", id: "sitemap"
      # the default, universal version of the gig guide
      concerns :gig_guide
      # edition based versions of the gig guide.
      scope "editions/:edition_id", as: "edition" do
        concerns :gig_guide
      end
      match "*path", to: "errors#not_found", via: :all
    end
  end

  # api.lml.live
  constraints subdomain: /^api$/ do
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)

    # TODO: we could redirect to web_root if we get the host config working
    get "/", to: redirect("https://www.livemusiclocator.com.au")
    # api.lml.live/gigs - including the main api concerns documente above

    scope "gigs" do
      # This has to go first or it will treat /gigs/feed.rss as a gig with id "feed"
      # TODO: add constraints to avoid this perhaps
      get "feed", to: "gigs#feed", defaults: { format: "rss" }

      # the main API routes defined above
      concerns :the_api
      # some other things I am not sure need to be here?
      get "autocomplete", to: "gigs#autocomplete", defaults: { format: "json" }
      get "for/:location/:date", to: "gigs#for", defaults: { format: "json" }
    end

    scope "venues" do
      get "autocomplete", to: "venues#autocomplete", defaults: { format: "json" }
    end
    scope "acts" do
      get "autocomplete", to: "acts#autocomplete", defaults: { format: "json" }
    end
    scope "docs" do
      get "/", to: "docs#index"
    end
  end

  # All the redirects

  # locally use lml.test for lml.live and livemusiclocator.com.test for livemusiclocator.com.au
  # bypassing many awkward tld_length issues hopefully

  # (if we need to do more complicated stuff like db lookups, maybe could call a controller and set params)

  short_domain = Rails.env.development? ? "lml.test" : "lml.live"
  target_domain = Rails.env.development? ? "livemusiclocator.com.test" : "livemusiclocator.com.au"

  # lml.live => www.livemusiclocator.com.au/?location=melbourne
  constraints domain: short_domain, subdomain: "" do
    get "/", to: redirect(status: 301, domain: target_domain, subdomain: "www", params: { location: "melbourne" }),
             via: :all
  end

  # Subdomain redirects to main gig guide, setting location search parameter
  %w[brisbane melbourne castlemaine goldfields].each do |standard_location|
    constraints domain: short_domain, subdomain: standard_location do
      get "/", to: redirect(status: 301,
                            domain: target_domain,
                            subdomain: "www",
                            params: { location: standard_location },),
               via: :all
    end
  end
  # Subdomain redirects to location-specific 'edition' of the gig guide
  %w[stkilda geelong].each do |edition_location|
    constraints domain: short_domain, subdomain: edition_location do
      get "/",
          to: redirect(status: 301,
                       domain: target_domain,
                       subdomain: "www",
                       path: "/editions/#{edition_location}",), via: :all
    end
  end
  # livemusiclocator.com.au => www.livemusiclocator.com.au
  constraints host: target_domain do
    get "/", to: redirect(status: 301,
                          domain: target_domain,
                          subdomain: "www",), via: :all
  end
end
# rubocop:enable Metrics/BlockLength
