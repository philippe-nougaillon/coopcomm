require "application_system_test_case"

class AuditAdherentFlowTest < ApplicationSystemTestCase

  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end

  def go_to_audit_page
    # Fermer la notification de connexion
    find("[data-testid='close_notification']").click

    # Cliquer sur le bouton 'audit trail' de la navbar 
    find("[data-testid='audit_trail']").click
    sleep(1)
  end

  test "Ne peut pas visiter l'index de l'audit trail" do
    visit admin_audits_url
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_no_selector "h1", text: "Activité"
  end

end