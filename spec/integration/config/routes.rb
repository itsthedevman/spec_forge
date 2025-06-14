# frozen_string_literal: true

Rails.application.routes.draw do
  # Status endpoint
  get "/status", to: "status#index"
  root "status#index"

  # Auth routes
  post "/auth/login", to: "auth#login"
  get "/auth/me", to: "auth#me"
  post "/auth/logout", to: "auth#logout"

  # Admin routes
  get "/admin/users", to: "admin#users"

  # User management
  resources :users

  # Data routes
  get "/data/types", to: "data#types"
  get "/data/users", to: "data#users"
  get "/data/headers", to: "data#headers"

  # Posts with nested comments
  resources :posts do
    resources :comments, only: [:index, :create]
  end

  # Comments standalone routes for update/delete
  resources :comments, only: [:update, :destroy]
end
