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
    # TODO: this still provided by the react app but should be migrated if we plan to keep it.
    get "/events", to: "explorer#index", as: :web_events
    get "/about", to: "pages#show", id: "about", as: :web_about_page
    get "/about/*id", to: "pages#show", as: :web_about_section_page
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
    scope module: "web" do
      # the default, universal version of the gig guide
      concerns :gig_guide
      # edition based versions of the gig guide.
      scope "editions/:edition_id", as: "edition", constraints: { edition_id: /stkilda/ } do
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
end
# rubocop:enable Metrics/BlockLength
