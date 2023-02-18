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

  post :session, to: 'sessions#create'
  get :session, to: 'session#new'
  delete :session, to: 'session#destroy'
  
  # resque server monitoring
  mount Resque::Server.new, at: '/jobs'
end
