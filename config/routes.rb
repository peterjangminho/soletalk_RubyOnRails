Rails.application.routes.draw do
  mount ActionCable.server => "/cable"
  get "/healthz", to: "ops/health#show"

  root "home#index"
  resources :insights, only: [ :index, :show ]
  resources :sessions, only: [ :index, :show, :new, :create ] do
    resources :messages, only: :create
  end
  resource :setting, only: [ :show, :update ]
  namespace :admin do
    get "jobs", to: "jobs#show"
  end
  resource :subscription, only: :show, controller: "subscription" do
    post "validate", on: :collection
  end
  namespace :webhooks do
    post "revenue_cat", to: "revenue_cat#create"
  end

  get "/auth/google_oauth2/callback", to: "auth/omniauth_callbacks#google_oauth2"
  get "/auth/failure", to: "auth/omniauth_callbacks#failure"

  namespace :api do
    get "protected", to: "protected#show"
    namespace :auth do
      post "google/native_sign_in", to: "google#native_sign_in"
    end

    namespace :ontology_rag do
      post "users/sync", to: "users#sync"
      post "query", to: "query#create"
    end

    namespace :voice do
      post "events", to: "events#create"
    end

    namespace :voice_chat do
      post "surface", to: "layers#surface"
      post "depth", to: "layers#depth"
      post "insight", to: "layers#insight"
    end
  end
end
