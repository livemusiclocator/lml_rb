Rails.application.routes.draw do
  namespace :web do
    root 'gigs#index'
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
