Rails.application.routes.draw do
  get "/status", to: "status#index"
  root "status#index"

  resources :users
end
