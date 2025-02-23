Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # Defines the root path route ("/")
  root "main#index"

  resources :artists
  resources :releases
  resources :tracks

  get :admin, to: 'admin#index'

  namespace :admin do
    resource :system, :library, :releases, :credentials, :themes
    resources :artists
  end

  post :sessions, to: 'sessions#create'
  get :sign_in, to: 'sessions#new', as: 'sign_in'
  delete :sign_out, to: 'sessions#destroy', as: 'sign_out'

  # Player routes
  get 'player/next_track', to: 'player#next_track'
  get 'player/previous_track', to: 'player#previous_track'
  get 'player/:id', to: 'player#show'

  get 'themes/variables', to: 'themes#variables'
end
