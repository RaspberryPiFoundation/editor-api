# frozen_string_literal: true

EditorApp::Engine.routes.draw do
  scope '/:locale', locale: /[a-z]{2}(-[A-Z]{2})?/ do
    root to: 'home#show', as: :home
    get '/education', to: 'education#show', as: :education
    get '/error', to: 'errors#show', as: :error
    resources :projects, only: %i[index show create update destroy], param: :identifier
  end

  root to: 'locales#show'
end
