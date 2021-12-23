Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  namespace :api do
    resource :default_project, only: %i[show create] do
      get '/html', to: 'default_projects#html'
      get '/python', to: 'default_projects#python'
    end

    namespace :projects do
      resources :phrases, only: %i[show update] do
        post 'remix', to: 'phrases#remix'
      end
    end
  end
end
