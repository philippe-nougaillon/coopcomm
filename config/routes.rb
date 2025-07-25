Rails.application.routes.draw do
  # Mount Mission Control Job's engine where you wish to have it accessible
  mount MissionControl::Jobs::Engine, at: "/jobs"

  devise_for :users
  # devise_for :users, controllers: {
  #   registrations: 'users/registrations',
  #   omniauth_callbacks: 'users/omniauth_callbacks'
  # }

  devise_scope :user do
    authenticated :user do
      root 'interventions#index', as: :authenticated_root
    end

    unauthenticated do
      root 'pages#welcome', as: :unauthenticated_root
    end
  end

  resources :users do
    collection do
      get :agent_calendrier
    end
  end

  resources :mail_logs do
    collection do
      get :refresh
    end
  end
  match 'notifications', to: 'mail_logs#index', via: :get
  resources :tools
  resources :wiki_pages
  match 'wiki', to: 'wiki_pages#index', via: :get

  # resources :organisations, only: %i[ show edit update ]

  resources :interventions do
    member do
      # get :accepter
      # get :en_cours
      get :terminer
      get :valider
      get :refuser
      get :archiver
      delete :purge
      get :pointer
      get :pointage_statut
    end

    collection do
      get :get_unavailable_elements
    end
  end

  namespace :admin do
    get :audits
    get :create_new_user
    post :create_new_user_do
    get :messagerie
    post :send_notification
    get :stats
  end

  controller :pages do
    get :welcome, to: 'pages#welcome', as: :welcome
    get :assistant, to: 'pages#assistant', as: :assistant
    get :mentions_legales, to: 'pages#mentions_legales', as: :mentions_legales
    get :dashboard, to: 'pages#dashboard', as: :dashboard
    get :solution, to: 'pages#solution', as: :solution
    get :tarifs, to: 'pages#tarifs', as: :tarifs
    get :contact, to: 'pages#contact', as: :contact
  end

  resources :documents, only: %i[] do
    member do
      get :valider
      get :refuser
    end
  end

  resources :newsletters, only: %i[index new destroy]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check

  get "/service-worker.js" => "service_worker#service_worker"
  get "/manifest.json" => "service_worker#manifest"

  post '/twilio/whatsapp_reply', to: 'twilio#whatsapp_reply'
  get '/twilio/get_request', to: 'twilio#get_request'
  post '/twilio/get_request', to: 'twilio#get_request'

  # Defines the root path route ("/")
  root "interventions#index"
end
