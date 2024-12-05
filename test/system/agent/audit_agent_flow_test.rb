require "application_system_test_case"

class AuditAgentFlowTest < ApplicationSystemTestCase

  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test "Ne peut pas visiter l'index de l'audit trail" do
    visit admin_audits_url
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_no_selector "h1", text: "Activité"
  end

end