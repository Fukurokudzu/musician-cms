require 'resque/server'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "artists#index"

  resources :artists do
    post :scan
  end
  
  resources :releases
  
  get :admin, to: 'admin#index'
 
  namespace :admin do
    resource :system, :artists, :releases, :credentials, only: [:show, :update, :destroy]
  end

  post :sessions, to: 'sessions#create'
  get :sign_in, to: 'sessions#new', as: 'sign_in'
  delete :sign_out, to: 'sessions#destroy', as: 'sign_out'
  
  # resque server monitoring
  mount Resque::Server.new, at: '/jobs'
end
