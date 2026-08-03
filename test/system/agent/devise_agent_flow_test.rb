# frozen_string_literal: true

require 'application_system_test_case'

class DeviseAgentFlowTest < ApplicationSystemTestCase
  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test 'Se déconnecter' do
    # Fermer la notification de connexion
    fermer_notification

    # Anti-flake (déconnexion) : clic JS sur l'ancre + confirm stubé + re-essai, cf.
    se_deconnecter

    visit interventions_url
    assert_current_path new_user_session_path
  end
end
