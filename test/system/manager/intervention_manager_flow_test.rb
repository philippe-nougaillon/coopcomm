require "application_system_test_case"

class InterventionManagerFlowTest < ApplicationSystemTestCase

  setup do
    # @manager = users(:hidalgo)
    # login(@manager)
  end

  # teardown do
  #   Rails.cache.clear
  # end

  test "Voir la liste des interventions" do
    visit interventions_url
    assert_selector "h1", text: "Interventions"
  end

  # # test "Créer intervention" do
  # #   click_on "Ajouter une Intervention"
  # #   fill_in "Description", with: "Tailler les arbres"
  # #   # fill_in "Mots clés", with: "tailler"
  # #   # js_select 'tailler', from: 'Mots clés'
  # #   # find("select[id='intervention_adherent_id']").select_option('Weil Ariel')
  # #   # select = find("select[id='intervention_adherent_id']")
  # #   select "Weil Ariel", from: "Adhérent"
  # #   # js_select "Weil Ariel", from: "Adhérent"
  # #   # select_from_slim_select("Weil Ariel", from: "Adhérent")
  # #   # js_select "Team Électricité", from: "Équipe"
  # #   # js_select "Bond James", from: "Agent 1"
  # #   fill_in 'Début', with: DateTime.current.strftime("%m%d%Y\t%I%M%P")
  # #   fill_in 'Fin', with: (DateTime.current + 8.hours).strftime("%m%d%Y\t%I%M%P")
  # #   page.select "1.0", from: "Temps de pause (h)"
  # #   fill_in "Commentaires", with: "Ceci est un commentaire !"
  # #   click_on "Créer un(e) Intervention"
  # #   assert_text "Intervention créée avec succès."
  # # end

  test "Modifier intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on "Modifier"
    fill_in "Description", with: "Installer la fibre"
    click_on "Modifier ce(tte) Intervention"
    assert_no_text "Modifier intervention"
    assert_text "Installer la fibre"
  end

  test "Supprimer intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    delete_button = find("[data-testid=\"Supprimer l'intervention\"]")
    page.accept_confirm do
      delete_button.click
    end
    assert_text "Intervention supprimée avec succès."
  end

  test "Terminer une intervention" do
    find("a:not([disabled])", text: "Terminer", match: :first).click
    assert_text "Intervention terminée"
  end

  test "Valider une intervention" do
    find("a:not([disabled])", text: "Valider", match: :first).click
    assert_text "Intervention validée"
  end

  test "Refuser une intervention" do
    find("a:not([disabled])", text: "Refuser", match: :first).click
    assert_text "Intervention refusée"
  end

  # # test "Les filtres fonctionnent dans la liste des interventions" do
  # # end

  # # test "Le temps total d'une intervention est correctement calculé" do
  # # end

  # # test "Export XLS des interventions" do
  # # end

end