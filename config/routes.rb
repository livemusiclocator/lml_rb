Rails.application.routes.draw do
  # all the routes making up the api (well the main parts anyway) - accessible from api.lml.live/gigs and maybe from www.livemusiclocator.com.au/api/gigs too
  concern :the_api do
    root to: "gigs#index", defaults: { format: "json" }
    get "query", to: "gigs#query", defaults: { format: "json" }
    get ":id", to: "gigs#show", defaults: { format: "json" }
  end

  # provides the gig_guide pages for main www site and the editions , including static pages
  concern :gig_guide do
    root to: "explorer#index", as: :web_root
    scope "gigs" do
      get ":id", to: "explorer#show"
    end
    # todo: this still provided by the react app but should be migrated if we plan to keep it.
    get "/events", to: "explorer#index", as: :web_events
    get "/about", to: 'pages#show', id: "about", as: :web_about_page
    get '/about/*id', to: 'pages#show', as: :web_about_section_page
  end

  # Web front end - mapped to www and beta (for testing) subdomains - includes an api endpoint
  constraints subdomain: /^www|beta$/ do
    scope "api/gigs", as: "web_api" do
      concerns :the_api
    end
    scope module: "web" do
      concerns :gig_guide
      scope "editions/:edition_id", as: "edition", constraints: { edition_id: /stkilda/ } do
        concerns :gig_guide
      end
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "/", to: redirect("https://www.livemusiclocator.com.au")

  # Defines the root path route ("/")
  # root "posts#index"
  #
  scope "gigs" do
    concerns :the_api
    get "autocomplete", to: "gigs#autocomplete", defaults: { format: "json" }
    get "feed", to: "gigs#feed", defaults: { format: "rss" }
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
