require "application_system_test_case"

class ToolsTest < ApplicationSystemTestCase
  setup do
    login(users(:hidalgo))
  end

  test "Voir la liste des outils" do
    visit tools_url
    assert_selector "h1", text: "Outils / Machine"
  end

  test "Créer un outil" do
    visit tools_url

    click_sur_boutton_ajouter("outil")

    fill_in "Nom", with: "Tondeuse à gazon"
    fill_in "Description", with: "Tondeuse professionnelle acier inox Marina Systems MX57SH3V moteur Honda GXV160"
    fill_in "Modèle", with: "MX57SH3V"
    fill_in "Marque", with: "Marina Systems"
    within("#tool_icon_name") do
      find("option", text: "Tracteur").click
    end

    click_on "enregistrer_tool"

    assert_text "Outil créé avec succès."
  end

  test "Supprimer un outil" do
    visit tool_url(tools(:outil_paris))

    accept_confirm do
      click_on "supprimer_outil"
    end

    assert_text "Outil supprimé avec succès."
  end

  test "Ne pas pouvoir supprimer un outil avec une intervention" do
    visit tool_url(tools(:tondeuse))

    assert_selector "#supprimer_outil[disabled]"
  end
end
