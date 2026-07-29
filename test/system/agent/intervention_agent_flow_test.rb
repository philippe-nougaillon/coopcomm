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

    # « Bon d'intervention » agent : pas de description (générée automatiquement), service
    # caché ; on saisit l'adhérent, le créneau réalisé (passé) et le commentaire.
    # Date ancrée sur le vendredi précédant le lundi de la fixture tonte_locaux :
    # toujours passée, jamais en conflit, quel que soit le jour d'exécution.
    date = (Date.today - 1).beginning_of_week - 3
    select_option('#intervention_adherent_id', 'Bruel Patrick') # adhérent du service de bond

    fill_in 'Début', with: date.strftime('%m%d%Y')
    select '08', from: 'intervention_début_hour'
    select '00', from: 'intervention_début_minute'
    fill_in 'Fin', with: date.strftime('%m%d%Y')
    select '16', from: 'intervention_fin_hour'
    select '00', from: 'intervention_fin_minute'
    page.select '1,0', from: 'Temps de pause (h)'
    fill_in 'Commentaires', with: 'Ceci est un commentaire !'

    assert_difference -> { Intervention.count }, 1 do
      # Destination inconnue d'avance : on attend que le formulaire ait été quitté
      # (le commentaire seul ne suffit pas — il est aussi dans le textarea).
      soumettre 'enregistrer_intervention'
      assert_text 'Ceci est un commentaire !'
    end

    intervention = Intervention.order(:created_at).last
    assert_equal 'Ceci est un commentaire !', intervention.commentaires
    assert_equal [@agent.id], intervention.agent_ids
  end

  test 'Modifier intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    click_on 'Modifier' # n'existe que sur le show : Capybara attend la navigation
    # Le formulaire agent n'expose pas la description : on modifie le commentaire
    commentaire = 'Pelouse tondue, bordures faites'
    fill_in 'Commentaires', with: commentaire

    assert_no_difference -> { Intervention.count } do
      # Attend que le formulaire ait été quitté avant de lire la page d'arrivée.
      soumettre 'enregistrer_intervention'
      assert_text commentaire
    end

    assert_equal commentaire, intervention.reload.commentaires
  end

  test 'Ne pas pouvoir supprimer intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    # Ancrage positif d'abord : sans lui, l'assertion négative passerait
    # trivialement sur l'index avant la fin de la navigation vers le show.
    assert_current_path intervention_path(intervention)
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
