# frozen_string_literal: true

require 'application_system_test_case'

class DeviseManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'Se déconnecter' do
    # Fermer la notification de connexion
    fermer_notification

    # Le lien de déconnexion visible est dans le dropdown du dock mobile (replié) : on
    # stube le window.confirm de Turbo et on dispatche le clic en JS sur l'ancre (testid)
    page.execute_script('window.confirm = () => true')
    page.execute_script("document.querySelector(\"[data-testid='fermer_session']\").click()")
    # Le layout public n'affiche pas le flash : on vérifie l'état déconnecté
    assert_text 'Mutualisez mieux', wait: 10
    visit interventions_url
    assert_current_path new_user_session_path
  end
end
