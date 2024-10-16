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

  get '/player', to: 'player#show'
  patch '/player/update_track', to: 'player#update_track'

  get 'themes/variables', to: 'themes#variables'
end
