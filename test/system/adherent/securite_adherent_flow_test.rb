require "application_system_test_case"

class SecuriteAdherentFlowTest < ApplicationSystemTestCase

  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end


  test "Ne pas avoir accès aux informations d'une autre organisation" do
    user = users(:manager_marseille)
    intervention = interventions(:nettoyage_port)
    assert_no_text intervention.description
    visit users_url
    assert_no_text user.nom_prénom
    visit user_url(user.slug)
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_selector "h1", text: "Interventions"
  end

end