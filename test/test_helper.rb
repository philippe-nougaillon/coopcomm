# frozen_string_literal: true

require_relative 'simplecov_boot'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'bcrypt'
require 'capybara/rails'
require 'capybara/dsl'
require 'webmock/minitest' # Permet de stopper les requêtes en dehors du serveur (Ex: API météo)
require_relative 'failed_tests_reporter'

# Le hook global posé par `sign_in` est drainé par la 1re requête venue : sous
# `test:all`, une requête navigateur retardataire volait le login du test
# d'intégration suivant. La file est rendue invisible hors du thread de test.
module Warden
  module Test
    module WardenHelpers
      def _on_next_request
        return [] unless Thread.current == Thread.main

        @_on_next_request ||= []
      end
    end
  end
end

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers

    # L'environnement de test désactive le cache de fragments : sans ce bloc, un
    # test ne peut pas voir ce que la prod sert depuis le cache.
    # `collection_cache` est figé au démarrage : le remplacer est indispensable
    # pour qu'un `render collection:, cached:` écrive quoi que ce soit.
    def avec_cache
      store_initial = ActionView::PartialRenderer.collection_cache
      store = ActiveSupport::Cache::MemoryStore.new
      ActionView::PartialRenderer.collection_cache = store
      ActionController::Base.cache_store = store
      ActionController::Base.perform_caching = true
      yield store
    ensure
      ActionController::Base.perform_caching = false
      ActionController::Base.cache_store = store_initial
      ActionView::PartialRenderer.collection_cache = store_initial
    end

    # Parallélisation en opt-in : `PARALLEL_WORKERS=4 bin/rails test:all`.
    # Au-delà de 4, les tests système saturent.
    if ENV['PARALLEL_WORKERS']
      # Rails lit lui-même PARALLEL_WORKERS et ignore la valeur ci-dessous.
      parallelize(workers: :number_of_processors)

      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      end

      parallelize_teardown do |_worker|
        SimpleCov.result
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def refresh_dashboard_views!
      DashboardRefreshable.refresh_views!
    end

    # Peut servir par la suite : permet de nettoyer le cache après chaque test
    # teardown do
    #   Rails.cache.clear
    # end

    setup do
      # Pour accepter les requêtes vers le serveur lui-même
      WebMock.disable_net_connect!(allow_localhost: true)

      # WebMock intercepte les appels à l'API météo.
      stub_request(:get, /api.meteo-concept.com/)
        .to_return(
          status: 200,
          body: File.read('test/fixtures/files/responseMeteoConcept.json'),
          headers: { 
            'Content-Type' => 'application/json',
            'Date' => Time.now.httpdate
          }
        )

      # Simule les données pour l'API de Google routes
      stub_request(:post, /routes.googleapis.com/)
        .to_return(
          status: 200,
          body: File.read('test/fixtures/files/responseRoutesInfos.json'),
          headers: { 
            'Content-Type' => 'application/json',
          }
        )
    end

    def login(user)
      visit new_user_session_path
      # Si la session du test précédent subsiste, la page de connexion redirige.
      unless page.has_css?('#user_email', wait: 3)
        Capybara.reset_sessions!
        visit new_user_session_path
      end

      fill_in 'user_email', with: user.email, wait: 5
      fill_in 'user_password', with: 'qtDug$d843sqACz?V' # équivalent à encrypted_password: "$2a$12$wUPQBoF.qOQFwEShvv.4ZOpHEuH82EJwyCRd2zgajRlYzpO8n277q", généré avec Devise::Encryptor.digest(User, "password123")
      # Le bouton du FORMULAIRE (la navbar publique a aussi un « Se connecter »)
      find('input[type="submit"][value="Se connecter"]').click
      # Attendre la fin effective du login : sans ça, la navigation suivante peut
      # survenir avant que la session soit posée.
      assert_no_selector('#user_email', wait: 10)
    end

    def intervention_for_params(intervention)
      {
        intervention: {
          organisation_id: intervention.organisation_id,
          début: intervention.début,
          fin: intervention.fin,
          temps_de_pause: intervention.temps_de_pause,
          description: intervention.description,
          workflow_state: intervention.workflow_state,
          adherent_id: intervention.adherent_id,
          temps_total: intervention.temps_total,
          commentaires: intervention.commentaires,
          note: intervention.note,
          avis: intervention.avis,
          repeter: intervention.repeter,
          slug: SecureRandom.uuid,
          début_prévue: intervention.début_prévue,
          fin_prévue: intervention.fin_prévue
        }
      }
    end

    def activate_dropdown_slimSelect(id)
      # Pour activer le dropdown de slimselect
      ss_main = find(id, visible: false).sibling('div.ss-main')
      ss_main.click
    end

    # Courses connues sur les slim-select des formulaires dynamiques.
    RACE_SLIM_SELECT = [Capybara::ElementNotFound,
                        Selenium::WebDriver::Error::StaleElementReferenceError,
                        Selenium::WebDriver::Error::ElementClickInterceptedError].freeze

    # `dynamic-select` repeuple les selects en cascade (adhérent → services →
    # agents) : chaque repopulation vide puis reconstruit la liste, d'où les
    # retries. Un menu resté ouvert intercepterait le clic suivant.
    def select_option(id, value)
      tentatives = 0
      begin
        activate_dropdown_slimSelect(id)
        # Filtrer avant de cliquer : pendant l'animation d'ouverture, un clic
        # direct par texte atteint parfois la mauvaise option.
        find('.ss-search input', visible: true).set(value)
        within('.ss-list') do
          find('div.ss-option', text: value, match: :first).click
        end
      rescue *RACE_SLIM_SELECT
        tentatives += 1
        raise if tentatives >= 3

        fermer_menus_slim_select
        sleep 0.4 # backoff délibéré : laisse retomber la repopulation en vol
        retry
      end
    end

    # Le gestionnaire « clic extérieur » de slim-select capte le clic sur body.
    def fermer_menus_slim_select
      page.execute_script('document.body.click()')
      has_no_selector?('.ss-option', visible: true, wait: 2)
    end

    # Add more helper methods to be used by all tests here...
  end
end
