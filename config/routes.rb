# frozen_string_literal: true

Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/', graphql_path: '/graphql#execute' unless Rails.env.production?

  namespace :api do
    resource :default_project, only: %i[show] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[index show update destroy create] do
      resource :remix, only: %i[show create], controller: 'projects/remixes'
      resource :images, only: %i[show create], controller: 'projects/images'
    end

    resource :project_errors, only: %i[create]

    resources :schools, only: %i[index show create update] do
      resources :classes, only: %i[index show create update], controller: 'school_classes' do
        resources :members, only: %i[index create], controller: 'class_members'
      end

      resources :owners, only: %i[create destroy], controller: 'school_owners'
      resources :teachers, only: %i[create destroy], controller: 'school_teachers'
      resources :students, only: %i[create update destroy], controller: 'school_students'
    end
  end

  resource :github_webhooks, only: :create, defaults: { formats: :json }
end
