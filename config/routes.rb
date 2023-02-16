require 'resque/server'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "artists#index"

  resources :artists do
    post :scan
  end
  
  resources :releases

  mount Resque::Server.new, at: '/jobs'
end
