Rails.application.routes.draw do
  root "home#index"

  devise_for :users,
    controllers: { registrations: "users/registrations" }

  # User profile
  get "/profile", to: "users#show"
  get "/settings/profile", to: "users#edit"
  patch "/settings/profile", to: "users#update"
  get "/u/:username", to: "users#public_profile", as: :public_profile

  # Movies routes
  resources :movies, only: [ :index, :show ]
  get "movies/search", to: "movies#search", as: :movies_search

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
