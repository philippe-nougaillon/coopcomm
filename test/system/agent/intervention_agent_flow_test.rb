require "application_system_test_case"

class InterventionAgentFlowTest < ApplicationSystemTestCase

  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test "Voir la liste des interventions en se connectant" do
    assert_selector "h1", text: "Interventions"
  end

  test "Ne voir que ses interventions" do
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_agent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  test "Créer intervention" do
    click_link "ajouter_une_intervention"
    fill_in "Description", with: "Tailler les arbres"
    # find('div.ss-placeholder', text: "Choisissez un ou plusieurs mots clés").click
    # page.driver.browser.switch_to.active_element.send_keys('Coupure électricité', :enter, 'Réparation', :enter)
    
    ss_main = find("#intervention_adherent_id", visible: false).sibling('div.ss-main')
    ss_main.click

    within('.ss-list') do
      find('div.ss-option', text: "Weil Ariel").click
    end

    # find('div.ss-single', text: "Choisissez une équipe").click
    # page.driver.browser.switch_to.active_element.send_keys('Élec', :down, :enter)
    # find('div.ss-single', text: "Choisissez un agent", match: :first).click
    # page.driver.browser.switch_to.active_element.send_keys(:down, :enter)
    
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

  test "Ne pas pouvoir supprimer intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    assert_no_selector "[data-testid=\"Supprimer l'intervention\"]"
  end

  # test "Ne pas pouvoir terminer une intervention" do
  #   assert_selector "a[disabled]", text: "Terminer"
  # end

  test "Ne pas pouvoir valider une intervention" do
    assert_selector "a[disabled]", text: "Valider"
  end

  test "Ne pas pouvoir refuser une intervention" do
    assert_selector "a[disabled]", text: "Refuser"
  end

  # test "Les filtres fonctionnent dans la liste des interventions" do
  # end

  # test "Le temps total d'une intervention est correctement calculé" do
  # end

  # test "Export XLS des interventions" do
  # end

end