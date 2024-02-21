# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    mount GoodJob::Engine => 'good_job'
    resources :components
    resources :projects do
      delete :images, on: :member, action: :destroy_image
    end

    root to: 'projects#index'
  end

  post '/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/graphql', graphql_path: '/graphql#execute' unless Rails.env.production?

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

    resources :schools, only: %i[index show create update destroy] do
      resources :classes, only: %i[index show create update destroy], controller: 'school_classes' do
        resources :members, only: %i[index create destroy], controller: 'class_members'
      end

      resources :owners, only: %i[index create destroy], controller: 'school_owners'
      resources :teachers, only: %i[index create destroy], controller: 'school_teachers'
      resources :students, only: %i[index create update destroy], controller: 'school_students' do
        post :batch, on: :collection, to: 'school_students#create_batch'
      end
    end

    resources :lessons, only: %i[index create show update]
  end

  resource :github_webhooks, only: :create, defaults: { formats: :json }

  root to: 'auth#index'

  post '/auth/rpi', as: 'login'
  get '/auth/callback', to: 'auth#callback', as: 'callback'
  get '/logout', to: 'auth#destroy', as: 'logout'
end
