# frozen_string_literal: true

require 'application_system_test_case'

class InterventionAgentFlowTest < ApplicationSystemTestCase
  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test 'Voir la liste des interventions en se connectant' do
    # Depuis #291 la connexion arrive sur la page d'accueil, pas sur la liste
    assert_selector 'h1', text: 'Bonjour'
    visit interventions_url
    assert_selector 'h1', text: 'Interventions'
  end

  test 'Ne voir que ses interventions' do
    visit interventions_url
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_agent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  test 'Créer intervention' do
    visit interventions_url
    click_sur_boutton_ajouter('intervention')

    # « Bon d'intervention » agent : pas de description (générée automatiquement),
    # service caché ; on saisit l'adhérent, le créneau réalisé (passé) et le commentaire
    select_option('#intervention_adherent_id', 'Bruel Patrick') # adhérent du service de bond

    fill_in 'Début', with: (Date.today - 1).strftime('%m%d%Y')
    select '08', from: 'intervention_début_hour'
    select '00', from: 'intervention_début_minute'
    fill_in 'Fin', with: (Date.today - 1).strftime('%m%d%Y')
    select '16', from: 'intervention_fin_hour'
    select '00', from: 'intervention_fin_minute'
    page.select '1,0', from: 'Temps de pause (h)'
    fill_in 'Commentaires', with: 'Ceci est un commentaire !'
    click_on 'enregistrer_intervention'
    assert_text 'Intervention créée avec succès.'
  end

  test 'Modifier intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on 'Modifier'
    # Le formulaire agent n'expose pas la description : on modifie le commentaire
    fill_in 'Commentaires', with: 'Pelouse tondue, bordures faites'
    click_on 'enregistrer_intervention'
    assert_text 'Intervention modifiée avec succès'
    assert_text 'Pelouse tondue, bordures faites'
  end

  test 'Ne pas pouvoir supprimer intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    assert_no_selector "[data-testid=\"Supprimer l'intervention\"]"
  end

  # test "Ne pas pouvoir terminer une intervention" do
  #   assert_selector "a[disabled]", text: "Terminer"
  # end

  test 'Ne pas pouvoir valider une intervention' do
    visit interventions_url
    assert_no_button 'Valider'

    visit intervention_url(interventions(:nouvelle_intervention))
    assert_no_button 'Valider'
  end

  test 'Ne pas pouvoir refuser une intervention' do
    visit interventions_url
    assert_no_button 'Refuser'

    visit intervention_url(interventions(:nouvelle_intervention))
    assert_no_button 'Refuser'
  end

  # test "Les filtres fonctionnent dans la liste des interventions" do
  # end

  # test "Le temps total d'une intervention est correctement calculé" do
  # end

  # test "Export XLS des interventions" do
  # end
end
