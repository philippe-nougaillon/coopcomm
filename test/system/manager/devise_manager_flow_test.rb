require "application_system_test_case"

class DeviseManagerFlowTest < ApplicationSystemTestCase

  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test "Se déconnecter" do
    # Fermer la notification de connexion
    find("[data-testid='close_notification']").click

    logout_button = find("[title=\"Fermer la session de #{@manager.email} (#{@manager.rôle})\"]")
    page.accept_confirm do
      logout_button.click
    end
    assert_text "Déconnecté(e) avec succès."
    visit interventions_url
    assert_text "Vous devez vous connecter ou vous enregistrer pour continuer."
  end

end