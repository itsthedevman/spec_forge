Rails.application.routes.draw do
  get "/status", to: "status#index"
  root "status#index"

  resources :users

  get "/data/types", to: "data#types"
  get "/data/users", to: "data#users"
end
