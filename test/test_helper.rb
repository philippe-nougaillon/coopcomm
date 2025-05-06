ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'bcrypt'
require "capybara/rails"
require "capybara/dsl"

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Peut servir par la suite : permet de nettoyer le cache après chaque test
    # teardown do
    #   Rails.cache.clear
    # end

    def login(user)
      visit new_user_session_path

      fill_in "user_email", with: user.email
      fill_in "user_password", with: "qtDug$d843sqACz?V" # équivalent à encrypted_password: "$2a$12$wUPQBoF.qOQFwEShvv.4ZOpHEuH82EJwyCRd2zgajRlYzpO8n277q", généré avec Devise::Encryptor.digest(User, "password123")
      click_on "Se connecter"
      sleep(1)
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
          team_id: intervention.team_id,
          avis: intervention.avis,
          repeter: intervention.repeter,
          slug: SecureRandom.uuid,
          début_prévue: intervention.début_prévue,
          fin_prévue: intervention.fin_prévue
        }
      }
    end

    # Add more helper methods to be used by all tests here...
  end
end
