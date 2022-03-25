# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    resource :default_project, only: %i[show create] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    resources :projects, only: %i[show update] do
      resource :remix, only: %i[create], controller: 'projects/remixes'
      resource :images, only: %i[create], controller: 'projects/images'
    end
  end
end
