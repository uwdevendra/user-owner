UserService::Application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  scope "(:locale)", :locale => /#{I18n.available_locales.join('|')}/ do
    mount Doorkeeper::Engine => '/oauth'
    mount SudoMode::Engine => '/sudo'

    get 'register', :to => 'organizations#new', :as => 'register'
    get 'login', :to => 'sessions#new', :as => 'login'
    get 'logout', :to => 'sessions#destroy', :as => 'logout'

    # bug fix 
    get '/organizations/:id/users', :to => 'organizations#edit'

    get 'deactivated_organization', :to => 'static_pages#deactivated_organization', :as => 'deactivated'

    resources :sessions
    resources :password_resets
    resources :organizations do
      resources :users, :except => [:destroy]
      put 'activate', 'deactivate'
    end

    resources :documents, :only => [:new, :create, :index,:dummy ]

    root :to => 'sessions#new'
  end

  namespace :api, :defaults => { :format => 'json' } do
    scope :module => :v1 do
      get 'me', :to => "users#me"
      get 'users/users_for_ids', :to => "users#users_for_ids"
      get 'users/validate_users', :to => "users#validate_users"
      get 'organizations/validate_orgs', :to => "organizations#validate_orgs"
      resources :organizations, :shallow => true, :only => [:index, :show] do
        resources :users, :shallow => true, :only => [:index]
      end
      resources :deleted_organizations, :shallow => true, :only => :index
    end
  end
end
