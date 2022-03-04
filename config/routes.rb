# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :api do
    resource :default_project, only: %i[show create] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[show update] do
      resources :phrases, only: %i[show update] do
        resource :remix, only: %i[create]
      end
    end
  end
end
