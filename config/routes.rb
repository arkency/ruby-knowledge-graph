Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount RubyEventStore::Browser::App.for(event_store_locator: -> { Rails.configuration.event_store }), at: "/res"

  mount McpRackApp.new, at: "/mcp"

  get ".well-known/oauth-authorization-server", to: "oauth#metadata"
  scope :oauth do
    post "register", to: "oauth#register"
    get "authorize", to: "oauth#authorize"
    post "authorize", to: "oauth#approve", as: :oauth_approve
    post "token", to: "oauth#token"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    post "ingest", to: "ingestion#create"
  end

  resources :nodes, only: [ :index, :show ], param: :slug
  resources :ingestions, only: [ :index, :show ] do
    post :extract, on: :member
  end
  resources :extractions, only: [ :index, :show ]

  root "nodes#index"
end
