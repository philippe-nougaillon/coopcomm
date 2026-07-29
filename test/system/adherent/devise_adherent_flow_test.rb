# frozen_string_literal: true

require 'application_system_test_case'

class DeviseAdherentFlowTest < ApplicationSystemTestCase
  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end

  test 'Se déconnecter' do
    # Fermer la notification de connexion
    fermer_notification

    # Le lien de déconnexion visible est dans le dropdown du dock mobile (replié) : le
    # helper stube le confirm de Turbo, dispatche le clic en JS et re-tente si besoin.
    se_deconnecter

    visit interventions_url
    assert_current_path new_user_session_path
  end
end
