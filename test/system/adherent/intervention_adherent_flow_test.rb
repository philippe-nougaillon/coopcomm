# frozen_string_literal: true

require 'application_system_test_case'

class InterventionAdherentFlowTest < ApplicationSystemTestCase
  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end

  test 'Voir la liste des interventions en se connectant' do
    # Depuis #291 la connexion arrive sur la page d'accueil, pas sur la liste
    assert_selector 'h1', text: 'Bonjour'
    visit interventions_url
    assert_selector 'h1', text: 'Interventions'
  end

  test 'Voir que ses interventions' do
    visit interventions_url
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_adhérent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  test 'Créer intervention' do
    visit interventions_url
    click_sur_boutton_ajouter('intervention')

    # Le formulaire adhérent se limite à la demande : description, service, créneau souhaité
    fill_in 'Description', with: 'Tailler les arbres'
    select_option('#intervention_service_id', 'Informatique')
    fill_in 'Début', with: DateTime.current.strftime("%m%d%Y\t%I%M%P")
    fill_in 'Fin', with: (DateTime.current + 8.hours).strftime("%m%d%Y\t%I%M%P")

    click_on 'enregistrer_intervention'
    assert_text 'Intervention créée avec succès.'
  end

  test 'Modifier intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on 'Modifier'
    fill_in 'Description', with: 'Installer la fibre'
    # La refonte UX vide le select Service à l'édition (required) : il faut re-choisir
    select_option('#intervention_service_id', 'Informatique')
    click_on 'enregistrer_intervention'
    assert_no_text 'Modifier intervention'
    assert_text 'Installer la fibre'
  end

  test 'Ne pas pouvoir supprimer intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    assert_no_selector "[data-testid=\"Supprimer l'intervention\"]"
  end

  test 'Ne pas pouvoir terminer une intervention' do
    # La policy réserve « terminer » aux agents/managers
    visit intervention_url(interventions(:nouvelle_intervention))
    assert_no_button 'Terminer'
  end

  test 'Valider une intervention' do
    # Depuis #291, l'adhérent valide depuis « Actions en attente » sur l'accueil
    fermer_notification
    click_button 'Valider', match: :first
    assert_text 'Intervention validée'
  end

  test 'Refuser une intervention' do
    # Depuis #291, l'adhérent refuse depuis « Actions en attente » sur l'accueil.
    # Depuis #358, les cotations à signer (rendues au-dessus) ont aussi un bouton
    # « Refuser » → on cible le formulaire de refus d'une INTERVENTION, pas le 1er bouton.
    fermer_notification
    find("form[action^='/interventions/'][action$='/refuser'] button", match: :first).click
    assert_text 'Intervention refusée'
  end

  # test "Les filtres fonctionnent dans la liste des interventions" do
  # end

  # test "Le temps total d'une intervention est correctement calculé" do
  # end

  # test "Export XLS des interventions" do
  # end
end
