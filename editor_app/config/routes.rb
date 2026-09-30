# frozen_string_literal: true

EditorApp::Engine.routes.draw do
  get '/session/token', to: 'session_tokens#show'

  scope '/:locale', locale: /[a-z]{2}(-[A-Z]{2})?/ do
    root to: 'home#show', as: :home
    get '/education', to: 'education#show', as: :education
    resources :projects, only: %i[index show new create edit update destroy], param: :identifier
  end

  root to: 'locales#show'
end
