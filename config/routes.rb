Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # Defines the root path route ("/")
  root "main#index"

  # Only public reading routes: creating and editing content is done in the
  # admin namespace, visitors never mutate anything.
  resources :artists, only: [:index, :show]
  resources :releases, only: [:index, :show] do
    member do
      get :download
    end
  end
  resources :tracks, only: [:show]

  get :admin, to: 'admin#index'

  namespace :admin do
    resource :about, only: [:show]
    resource :system, only: [:show, :update]
    resource :library, only: [:show, :update]
    resource :themes, only: [:show, :update, :destroy]
    resources :artists
    resources :releases do
      collection do
        get :new_upload
        post :upload
      end
      member do
        post :add_tracks
      end
    end
  end

  post :sessions, to: 'sessions#create'
  get :sign_in, to: 'sessions#new', as: 'sign_in'
  delete :sign_out, to: 'sessions#destroy', as: 'sign_out'

  # Player routes
  get 'player/next_track', to: 'player#next_track'
  get 'player/previous_track', to: 'player#previous_track'
  get 'player/:id', to: 'player#show'
end
