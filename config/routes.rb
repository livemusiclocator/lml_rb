Rails.application.routes.draw do
  namespace :web do
    root to: "explorer#index"
    scope "gigs" do
      get ":id", to: "explorer#show"
    end
    get "/events", to: "explorer#index"
    get "/about", to: '/high_voltage/pages#show', id: "about", as: :about_page
    get '/about/*id', to: '/high_voltage/pages#show', as: :about_section_page
    get "/about/contact", to: '/high_voltage/pages#show', id: "contact", as: :about_contact_page

    # Trying to see if the concept of 'editions' works for us here.
    # an edition will be a standard set of fairly hard coded parameters that we formerly called 'location' on front end
    # at a minimum they may have slightly different content on the about pages etc.
    # As we only have stkilda, we'll keep this fairly basic for now
    scope "editions/stkilda" do
      root to: "explorer#index", as: :stkilda_root, edition: "stkilda"
      get "/events", to: "explorer#index", edition: "stkilda"
      scope "gigs" do
        get ":id", to: "explorer#show", edition: "stkilda"
      end
      get "/about", to: '/high_voltage/pages#show', id: "stkilda_about"
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
  scope "gigs" do
    root to: "gigs#index", defaults: { format: "json" }
    get "query", to: "gigs#query", defaults: { format: "json" }
    get "autocomplete", to: "gigs#autocomplete", defaults: { format: "json" }
    get "feed", to: "gigs#feed", defaults: { format: "rss" }
    get ":id", to: "gigs#show", defaults: { format: "json" }
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
