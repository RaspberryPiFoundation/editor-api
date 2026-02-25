# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    mount GoodJob::Engine => 'good_job'
    resources :components

    mount Flipper::UI.app(Flipper) => '/flipper',
          constraints: AdminSessionConstraint.new

    resources :projects do
      delete :images, on: :member, action: :destroy_image
    end

    resources :schools, only: %i[index show edit update] do
      member do
        post :verify
        patch :reject
        patch :reopen
      end
    end

    resources :school_classes, only: %i[show]
    resources :lessons, only: %i[show]
    resources :school_import_results, only: %i[index show new create]

    root to: 'projects#index'
  end

  post '/test/reseed', to: 'test_utilities#reseed'

  post '/graphql', to: 'graphql#execute'
  mount GraphiQL::Rails::Engine, at: '/graphql', graphql_path: '/graphql#execute' unless Rails.env.production?

  namespace :api do
    namespace :scratch do
      resources :projects, only: %i[show update]
    end

    resource :default_project, only: %i[show] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[index show update destroy create] do
      get :finished, on: :member, to: 'school_projects#show_finished'
      get :context, on: :member, to: 'projects#show_context'
      put :finished, on: :member, to: 'school_projects#set_finished'
      get :status, on: :member, to: 'school_projects#show_status'
      post :unsubmit, on: :member, to: 'school_projects#unsubmit'
      post :submit, on: :member, to: 'school_projects#submit'
      post :return, on: :member, to: 'school_projects#return'
      post :complete, on: :member, to: 'school_projects#complete'
      resource :remix, only: %i[show create], controller: 'projects/remixes' do
        get :identifier, on: :member, to: 'projects/remixes#show_identifier'
      end
      resources :remixes, only: %i[index], controller: 'projects/remixes'
      resource :images, only: %i[show create], controller: 'projects/images'
      resources :feedback, only: %i[index create destroy], controller: 'feedback' do
        put :read, on: :member, to: 'feedback#set_read'
      end
    end

    resource :project_errors, only: %i[create]

    resource :school, only: [:show], controller: 'my_school'
    resources :schools, only: %i[index show create update destroy] do
      post :import, on: :collection
      resources :members, only: %i[index], controller: 'school_members'
      resources :classes, only: %i[index show create update destroy], controller: 'school_classes' do
        post :import, on: :collection
        resources :members, only: %i[index create destroy], controller: 'class_members' do
          post :batch, on: :collection, to: 'class_members#create_batch'
        end
      end

      resources :owners, only: %i[index], controller: 'school_owners'
      resources :teachers, only: %i[index create], controller: 'school_teachers'
      resources :students, only: %i[index create update destroy], controller: 'school_students' do
        post :batch, on: :collection, to: 'school_students#create_batch'
        delete :batch, on: :collection, to: 'school_students#destroy_batch'
      end
    end

    resources :lessons, only: %i[index create show update destroy] do
      post :copy, on: :member, to: 'lessons#create_copy'
    end

    resources :teacher_invitations, param: :token, only: :show do
      put :accept, on: :member
    end

    resources :user_jobs, only: %i[index show]
    resources :school_import_jobs, only: %i[show]

    post '/google/auth/exchange-code', to: 'google_auth#exchange_code', defaults: { format: :json }

    resources :features, only: %i[index]
  end

  resource :github_webhooks, only: :create, defaults: { formats: :json }

  root to: 'auth#index'

  post '/auth/rpi', as: 'login'
  get '/auth/callback', to: 'auth#callback', as: 'callback'
  get '/logout', to: 'auth#destroy', as: 'logout'
end
