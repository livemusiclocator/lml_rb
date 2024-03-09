Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  scope "gigs" do
    root to: "gigs#index", defaults: { format: "json" }
    get "query", to: "gigs#query", defaults: { format: "json" }
  end
  scope "venues" do
    get "query", to: "venues#query", defaults: { format: "json" }
  end
end
