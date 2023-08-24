# frozen_string_literal: true

Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'

  namespace :api do
    resource :default_project, only: %i[show] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[index show update destroy create] do
      resource :remix, only: %i[create], controller: 'projects/remixes'
      resource :images, only: %i[create], controller: 'projects/images'
    end

    resource :project_errors, only: %i[create]
  end

  resource :github_webhooks, only: :create, defaults: { formats: :json }
end
