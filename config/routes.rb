Rails.application.routes.draw do
  root "home#index"

  devise_for :users,
    controllers: { registrations: "users/registrations" }

  # User profile
  get "/profile", to: "users#show"
  get "/settings/profile", to: "users#edit"
  patch "/settings/profile", to: "users#update"
  get "/u/:username", to: "users#public_profile", as: :public_profile

end
