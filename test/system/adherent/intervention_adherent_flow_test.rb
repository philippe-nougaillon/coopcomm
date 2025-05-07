require "application_system_test_case"

class InterventionAdherentFlowTest < ApplicationSystemTestCase

  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end

  test "Voir la liste des interventions en se connectant" do
    assert_selector "h1", text: "Interventions"
  end

  test "Voir que ses interventions" do
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_adhérent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  test "Créer intervention" do
    click_on "Ajouter une Intervention"
    fill_in "Description", with: "Tailler les arbres"
    # find('div.ss-placeholder', text: "Choisissez un ou plusieurs mots clés").click
    # page.driver.browser.switch_to.active_element.send_keys('Coupure électricité', :enter, 'Réparation', :enter)
    find('div.ss-single', text: "Choisissez une équipe").click
    page.driver.browser.switch_to.active_element.send_keys('Élec', :down, :enter)
    find('div.ss-single', text: "Choisissez un agent", match: :first).click
    page.driver.browser.switch_to.active_element.send_keys(:down, :enter)
    fill_in 'Début', with: DateTime.current.strftime("%m%d%Y\t%I%M%P")
    fill_in 'Fin', with: (DateTime.current + 8.hours).strftime("%m%d%Y\t%I%M%P")
    page.select "1,0", from: "Temps de pause (h)"
    fill_in "Commentaires", with: "Ceci est un commentaire !"
    click_on "Créer un(e) Intervention"
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

  test "Ne pas pouvoir supprimer intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    assert_no_selector "[data-testid=\"Supprimer l'intervention\"]"
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