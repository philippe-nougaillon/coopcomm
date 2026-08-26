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

    # 1. Cliquer sur l'icône de déconnexion dans le menu/dock pour ouvrir la modale
    find("[data-testid='dropdown_mobile']").click

    # 2. Cliquer sur l'icône de déconnexion dans le menu/dock pour ouvrir la modale
    find("button[onclick*='logout_modal.showModal()']").click

    # 3. Confirmer la déconnexion dans la modale
    within '#logout_modal' do
      click_on 'Oui, se déconnecter'
    end

    # 4. Vérifier l'état déconnecté
    assert_text 'Mutualisez mieux', wait: 10
    visit interventions_url
    assert_current_path new_user_session_path
  end
end