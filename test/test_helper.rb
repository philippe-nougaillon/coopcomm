# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'rails' do
  add_group 'Components', 'app/components'
  add_group 'Mailboxes', 'app/mailboxes'
  add_group 'Policies', 'app/policies'
  add_group 'PDFs', 'app/pdfs'
  add_group 'Services', 'app/services'
  add_group 'Subscriptions', 'app/subscriptions'
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'bcrypt'
require 'capybara/rails'
require 'capybara/dsl'
require 'webmock/minitest' # Permet de stopper les requêtes en dehors du serveur (Ex: API météo)

# Correctif R3 (détail : `.claude/method/bugs-signales.md`) : le hook global posé
# par `sign_in` est drainé par la 1re requête venue — sous `test:all`, une requête
# navigateur retardée volait le login du test d'intégration suivant (302 vers
# /users/sign_in). La file est donc rendue invisible hors du thread de test.
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

    # Tests en parallèle, EN OPT-IN : séquentiel par défaut, parallèle si
    # PARALLEL_WORKERS est posé — ex. `PARALLEL_WORKERS=4 bin/rails test:all`
    # (12 workers = tests système saturés, cf. décision 2026-07-17-d).
    if ENV['PARALLEL_WORKERS']
      # Rails lit lui-même PARALLEL_WORKERS et ignore la valeur ci-dessous.
      parallelize(workers: :number_of_processors)

      # SimpleCov : chaque worker forké doit écrire son résultat sous un nom
      # distinct pour que la couverture finale soit fusionnée (sinon rapport
      # partiel/écrasé).
      parallelize_setup do |worker|
        SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}"
      end

      parallelize_teardown do |_worker|
        SimpleCov.result
      end
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Rafraîchit les vues matérialisées du dashboard à partir des fixtures
    # chargées.
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

      # Dès qu'un test système tente d'appeler l'API météo,
      # WebMock intercepte l'appel et renvoie une réponse vide.
      stub_request(:get, /api.meteo-concept.com/)
        .to_return(
          status: 200,
          body: File.read('test/fixtures/files/responseMeteoConcept.json'),
          headers: { 
            'Content-Type' => 'application/json',
            'Date' => Time.now.httpdate
          }
        )
    end

    def login(user)
      visit new_user_session_path
      # Filet anti-flake : si la session du test précédent subsiste (reset
      # incomplet), la page de connexion redirige vers l'accueil connecté.
      unless page.has_css?('#user_email', wait: 3)
        Capybara.reset_sessions!
        visit new_user_session_path
      end

      fill_in 'user_email', with: user.email, wait: 5
      fill_in 'user_password', with: 'qtDug$d843sqACz?V' # équivalent à encrypted_password: "$2a$12$wUPQBoF.qOQFwEShvv.4ZOpHEuH82EJwyCRd2zgajRlYzpO8n277q", généré avec Devise::Encryptor.digest(User, "password123")
      # Le bouton du FORMULAIRE (la navbar publique a aussi un « Se connecter »)
      find('input[type="submit"][value="Se connecter"]').click
      # Anti-flake : attendre la fin EFFECTIVE du login (on a quitté la page de
      # connexion → le champ email a disparu) plutôt qu'un sleep fixe. Sinon la
      # navigation suivante peut survenir avant que la session soit posée et
      # retomber sur l'écran de connexion.
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

    def select_option(id, value)
      activate_dropdown_slimSelect(id)
      # On filtre d'abord via la recherche du slim-select, puis on clique :
      # pendant l'animation d'ouverture, un clic direct par texte atteint
      # parfois la mauvaise option (la liste défile encore). En tapant la
      # valeur, il ne reste que l'option voulue → sélection déterministe.
      find('.ss-search input', visible: true).set(value)
      within('.ss-list') do
        find('div.ss-option', text: value, match: :first).click
      end
    end

    # Add more helper methods to be used by all tests here...
  end
end
