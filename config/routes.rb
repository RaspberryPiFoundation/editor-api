# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :components
    resources :projects do
      delete :images, on: :member, action: :destroy_image
    end

    root to: "projects#index"
  end

  post '/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/graphql', graphql_path: '/graphql#execute' unless Rails.env.production?

  namespace :api do
    resource :default_project, only: %i[show] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[index show update destroy create] do
      resource :share, only: %i[show create], controller: 'projects/share'
      resource :remix, only: %i[show create], controller: 'projects/remixes'
      resource :images, only: %i[show create], controller: 'projects/images'
    end

    resource :project_errors, only: %i[create]
  end

  resource :github_webhooks, only: :create, defaults: { formats: :json }

  root to: 'auth#index'

  post '/auth/rpi', as: 'login'
  get '/auth/callback', to: 'auth#callback', as: 'callback'
  get '/logout', to: 'auth#destroy', as: 'logout'
end
