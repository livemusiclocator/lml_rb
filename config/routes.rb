# frozen_string_literal: true

Rails.application.routes.draw do
  # Every id in this schema is a uuid, so a route constrained to one cannot
  # shadow a named collection route added later. A local, like short_domain
  # below - a constant here would land on Object. No anchors: rails rejects
  # them in a routing requirement, and segments are anchored already.
  uuid = /\h{8}-\h{4}-\h{4}-\h{4}-\h{12}/

  # all the routes making up the main parts of the api
  concern :the_api do
    root to: "api/gigs#index", defaults: { format: "json" }
    get "query", to: "api/gigs#query", defaults: { format: "json" }
    get ":id", to: "api/gigs#show", defaults: { format: "json" }
  end

  # all the routes providing the standard front end
  concern :gig_guide do
    root to: "explorer#index", as: :web_root
    scope "gigs" do
      get ":id", to: "explorer#show"
    end
    # The spa routes /acts/:id and /venues/:id client side; these are the pages
    # they land on, so a crawler and a cold load get the record rather than an
    # empty shell. Every client side route needs one of these - a refresh or a
    # shared link reaches rails first. See the README in the lml repo.
    scope "acts" do
      get ":id", to: "acts#show", constraints: { id: uuid }
    end
    scope "venues" do
      get ":id", to: "venues#show", constraints: { id: uuid }
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
  constraints subdomain: /^(beta|www).livemusiclocator/ do
    devise_for :users, path: "backstage",
                       class_name: "Lml::User",
                       controllers: {
                         sessions: "backstage/sessions",
                         registrations: "backstage/registrations",
                         passwords: "backstage/passwords",
                         confirmations: "backstage/confirmations",
                       },
                       path_names: { sign_in: "login", sign_out: "logout", sign_up: "register" }
    scope "/backstage", module: "backstage", as: "backstage" do
      root to: "dashboard#index"
      resources :proposals, only: [:index, :new, :create, :show]
      resources :api_tokens, only: [:index, :create, :destroy]
      namespace :search do
        resources :gigs, only: :index
        resources :acts, only: :index
        resources :venues, only: :index
      end
    end

    # mount the lml api handlers here
    scope "api/gigs", as: "web_api" do
      concerns :the_api
    end

    # The same DocsController as api.lml.live, in the web layout. Deliberately
    # outside the `module: "web"` scope below - it is not a Web:: controller -
    # and it has to come before that scope's "*path" catch all.
    get "docs", to: "docs#index", as: :web_docs

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
    devise_for :admin_users, ActiveAdmin::Devise.config.merge(class_name: "Lml::AdminUser")
    ActiveAdmin.routes(self)

    authenticate :admin_user do
      mount GoodJob::Engine => "/good_job"
    end

    # The bare api host is the most requested path on it, and every one of those
    # requests used to be bounced to the consumer gig guide. Someone typing or
    # curling api.lml.live wants the api, so answer with the signpost /gigs gives:
    # the name, the attribution, and where the documentation is.
    #
    # Named api_root because the :the_api concern already took the plain `root`
    # name for /gigs, which is the same action.
    get "/", to: "api/gigs#index", as: :api_root, defaults: { format: "json" }
    # api.lml.live/gigs - including the main api concerns documente above

    scope "gigs" do
      # These have to go first or the_api's ":id" swallows them - /gigs/autocomplete
      # spent its whole life being routed to gigs#show with id "autocomplete".
      # TODO: add constraints to avoid this perhaps
      get "feed", to: "api/gigs#feed", defaults: { format: "rss" }
      get "search", to: "api/gigs#search", defaults: { format: "json" }

      # the main API routes defined above
      concerns :the_api
      # some other things I am not sure need to be here?
      get "for/:location/:date", to: "api/gigs#for", defaults: { format: "json" }
    end

    # Admin-only autocomplete pickers, not public API - see PickerResults.
    scope "venues" do
      get "search", to: "venues#search", defaults: { format: "json" }
      # Temporary, and token gated rather than public - see VenuesController.
      get "autocomplete", to: "venues#autocomplete", defaults: { format: "json" }
      # Public read api, namespaced away from the pickers above - see the acts
      # scope below for the same split and why the uuid constraint is here.
      get ":id", to: "api/venues#show", constraints: { id: uuid }, defaults: { format: "json" }
    end
    scope "acts" do
      get "search", to: "acts#search", defaults: { format: "json" }
      # The public read API lives in its own namespace, away from the picker
      # above and from the html page on www, which will be Web::ActsController.
      # Same split for venues if they ever get a page. The uuid constraint keeps
      # this from swallowing the next /acts/something the way ":id" swallowed
      # /gigs/autocomplete for years.
      get ":id", to: "api/acts#show", constraints: { id: uuid }, defaults: { format: "json" }
    end
    # The api documentation - see DocsController. Also served on www below.
    get "docs", to: "docs#index"

    # The admin write API. Bearer token per admin, see Lml::ApiToken and
    # Api::V1::Admin::BaseController. Deliberately not under /admin, which
    # ActiveAdmin owns, and versioned from day one because callers build
    # against this and never come back to update.
    namespace :v1, module: "api/v1", defaults: { format: "json" } do
      namespace :admin do
        resources :venues, only: [:index, :show, :create, :update]
        resources :acts, only: [:index, :show, :create, :update]
        # No update: an upload is a record of what was sent, and reprocessing
        # edited content is a different thing to editing the record.
        resources :uploads, only: [:index, :show, :create]
        # Read only - writing gigs goes through uploads. `resources` puts the
        # collection route ahead of the ":id" member route, so /gigs/clipper is
        # not swallowed the way /gigs/autocomplete was.
        resources :gigs, only: [:index, :show] do
          get "clipper", on: :collection, defaults: { format: :text }
        end
      end
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
  # www.lml.live => www.livemusiclocator.com.au/?location=melbourne (copy pasted from "" subdomain handling above)
  constraints domain: short_domain, subdomain: "www" do
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
