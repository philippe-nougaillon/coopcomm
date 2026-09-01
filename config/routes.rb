# frozen_string_literal: true

Rails.application.routes.draw do
  # Mount Mission Control Job's engine where you wish to have it accessible
  mount MissionControl::Jobs::Engine, at: '/jobs'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  devise_for :users
  # devise_for :users, controllers: {
  #   registrations: 'users/registrations',
  #   omniauth_callbacks: 'users/omniauth_callbacks'
  # }

  devise_scope :user do
    authenticated :user do
      root 'pages#home', as: :authenticated_root
    end

    unauthenticated do
      root 'pages#welcome', as: :unauthenticated_root
    end
  end

  resources :absences, only: [:destroy]

  # `POST /users` est réservé par Devise dès que :registerable est réactivé
  # (devise_for est déclaré plus haut, il gagne) : la création d'un utilisateur
  # passe par admin#create_new_user (formulaire) et admin#create_new_user_do.
  resources :users, except: %i[new create] do
    member do
      post :inviter
      get :edit_password
      patch :update_password
      patch :reactivate
    end
    collection do
      get :agent_calendrier
      get :import
      post :import_do
    end
  end

  resources :mail_logs do
    collection do
      get :refresh
    end
  end
  match 'notifications', to: 'mail_logs#index', via: :get

  resources :mouvements, only: %i[index new create edit update]
  resources :tools do
    resources :mouvements, only: [] do
      collection do
        post :reserve
        post :libere
      end
    end
  end

  resources :documentation, controller: 'wiki_pages' do
    collection do
      get :blog
      get :guide
      get :faq
    end
  end
  match 'doc', to: redirect('/documentation'), via: :get

  # resources :organisations, only: %i[ show edit update ]

  resources :interventions do
    member do
      # post :accepter
      # post :en_cours
      post :terminer
      post :valider
      post :refuser
      post :archiver
      delete :purge
      delete :purger_photos_demande
      get :pointer
      get :pointage_statut
      patch :update_location
    end

    collection do
      get :get_unavailable_elements
      get :services_for_adherent
      get :agents_for_service
      get :new_intervention_modele_pointage
      post :create_intervention_modele_pointage
    end
  end

  namespace :admin do
    get :audits
    get :create_new_user
    post :create_new_user_do
    get :stats
    get :parametres
  end

  controller :pages do
    get :welcome, to: 'pages#welcome', as: :welcome
    get :assistant, to: 'pages#assistant', as: :assistant
    get :mentions_legales, to: 'pages#mentions_legales', as: :mentions_legales
    get :dashboard, to: 'pages#dashboard', as: :dashboard
    get :solution, to: 'pages#solution', as: :solution
    get :tarifs, to: 'pages#tarifs', as: :tarifs
    get :contact, to: 'pages#contact', as: :contact
    get :home, to: 'pages#home', as: :home
    get :meteo, to: 'pages#meteo', as: :meteo
    get :meteo_by_day
  end

  resources :documents, only: %i[] do
    member do
      # post :valider
      # post :refuser
    end
  end

  resources :newsletters, only: %i[index new destroy]

  resources :services, except: %i[index]
  resources :warehouses, except: %i[index], path: 'sites'

  get 'adherent_crm', to: 'adherent_crm#index', as: :adherent_crm

  resources :cotations do
    member do
      # Le nom de fichier termine l'URL (ex. .../Cotation-2026-1.pdf) pour que la
      # prévisualisation du navigateur affiche ce nom plutôt que "pdf.pdf".
      get 'pdf(/*filename)', action: :pdf, as: :pdf, format: false
      post :envoyer
      post :valider
      post :refuser
      post :create_commande
      get  :signer
      post :signer_do
    end
  end 
  resources :prestations, except: %i[index]

  resources :conventions do
    collection do
      get :services_for_adherent
    end
  end

  resources :commandes do
    member do
      get 'pdf(/*filename)', action: :pdf, as: :pdf, format: false
      post :envoyer
      post :valider
      post :refuser
      post :create_facture
    end
  end

  resources :factures do
    member do
      get 'pdf(/*filename)', action: :pdf, as: :pdf, format: false
      post :envoyer
      post :valider
      post :refuser
    end
  end

  namespace :messagerie do
    get '/', to: 'index', as: ''
    get 'conversation/:to_user_slug', to: 'conversation', as: 'conversation'
    post :mark_as_read
    post :send_message
    post :search_contact
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  get '/service-worker.js' => 'service_worker#service_worker'
  get '/manifest.json' => 'service_worker#manifest'

  post '/twilio/whatsapp_reply', to: 'twilio#whatsapp_reply'

  root 'pages#home'
end
