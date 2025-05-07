require "application_system_test_case"

class InterventionManagerFlowTest < ApplicationSystemTestCase

  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test "Voir la liste des interventions en se connectant" do
    assert_selector "h1", text: "Interventions"
  end

  test "Créer intervention" do
    click_on "ajouter_une_intervention"
    fill_in "Description", with: "Tailler les arbres"

    # Sélectionner le tag
    ss_main = find('#intervention_tags_manager', visible: false).sibling('div.ss-main')
    ss_main.click
    page.driver.browser.switch_to.active_element.send_keys('Coupure électricité', :enter, 'Réparation', :enter)

    # Sélectionner l'adhérent
    ss_main = find("#intervention_adherent_id", visible: false).sibling('div.ss-main')
    ss_main.click
    within('.ss-list') do
      find('div.ss-option', text: "Weil Ariel").click
    end

    # Sélectionner l'équipe
    ss_main = find("#intervention_team_id", visible: false).sibling('div.ss-main')
    ss_main.click
    within('.ss-list') do
      find('div.ss-option', text: "Électricité").click
    end

    # Sélectionner l'agent
    ss_main = find("#intervention_agent_ids", visible: false).sibling('div.ss-main')
    ss_main.click
    within('.ss-list') do
      find('div.ss-option', text: "Bond James").click
    end

    # Sélectionner les dates
    fill_in 'Début', with: DateTime.current.strftime("%m%d%Y\t%I%M%P")
    fill_in 'Fin', with: (DateTime.current + 8.hours).strftime("%m%d%Y\t%I%M%P")

    page.select "1,0", from: "Temps de pause (h)"
    fill_in "Commentaires", with: "Ceci est un commentaire !"
    click_on "enregistrer_intervention"
    assert_text "Intervention créée avec succès."
  end

  test "Modifier intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on "Modifier"
    fill_in "Description", with: "Installer la fibre"
    click_on "enregistrer_intervention"
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

  # test "Les filtres fonctionnent dans la liste des interventions" do
  # end

  # test "Le temps total d'une intervention est correctement calculé" do
  # end

  # test "Export XLS des interventions" do
  # end

end