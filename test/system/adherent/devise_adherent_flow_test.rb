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

    logout_button = find("[title=\"Fermer la session de #{@adhérent.email} (#{@adhérent.rôle})\"]")
    page.accept_confirm do
      logout_button.click
    end
    # Le layout public n'affiche pas le flash : on vérifie l'état déconnecté
    assert_text 'Mutualisez mieux'
    visit interventions_url
    assert_current_path new_user_session_path
  end
end
