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

    # Anti-flake (déconnexion). Deux pièges combinés :
    # 1) le clic Selenium natif sur le lien du dock mobile tombe sur le SVG
    #    enfant et n'atteint pas l'ancre → le DELETE Turbo n'est pas émis ;
    # 2) Turbo déclenche un window.confirm que page.accept_confirm capte de façon
    #    instable. On stube donc le confirm, puis on dispatche le clic en JS sur
    #    l'ancre (testid du dock), ce qui rend la déconnexion déterministe.
    page.execute_script('window.confirm = () => true')
    page.execute_script("document.querySelector(\"[data-testid='fermer_session']\").click()")
    # Le layout public n'affiche pas le flash : on vérifie l'état déconnecté.
    # Le DELETE + la redirection vers la landing peuvent dépasser le délai par
    # défaut (2 s) de Capybara.
    assert_text 'Mutualisez mieux', wait: 10
    visit interventions_url
    assert_current_path new_user_session_path
  end
end
