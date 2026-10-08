# frozen_string_literal: true

require 'test_helper'

# `terminer_destination` donne au bouton « Terminer » la même destination sur la home.
class InterventionsHelperTest < ActionView::TestCase
  # Le helper interroge `current_user`, fourni par le contrôleur en temps normal.
  attr_accessor :current_user

  setup do
    @mère  = interventions(:intervention_repete) # agents de fixture : bond, martin
    @fille = interventions(:intervention_fille)  # agent de fixture : martin
    @agent = users(:martin_technique_paris)
    # `début` épinglé sur aujourd'hui : la fixture est ancrée sur `4.hours.ago`, qui
    # bascule sur la veille entre minuit et 4 h.
    @fille.update_columns(template_slug: @mère.slug, début: Time.zone.now, fin: 1.hour.ago, temps_de_pause: 0)
  end

  test "l'agent du pointage est dirigé vers `pointer` de l'intervention modèle" do
    self.current_user = @agent

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  test 'un manager affecté comme agent du pointage est dirigé vers `pointer` comme les autres affectés' do
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: @mère)
    @fille.agents = [manager]
    self.current_user = manager

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  # B88 : `pointer` ferme le pointage de l'utilisateur connecté, pas celui affiché.
  test 'un agent du modèle qui n’est pas celui du pointage affiché est dirigé vers le formulaire, pas vers `pointer`' do
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: @mère)
    @fille.update_columns(fin: nil)
    self.current_user = manager

    assert_not @fille.agents.include?(manager), 'garde : la fille est le pointage de quelqu’un d’autre'
    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test 'un utilisateur non affecté à l’intervention modèle est dirigé vers `terminer` en POST' do
    self.current_user = users(:manager_paris)

    assert_not @mère.agents.include?(current_user), 'garde : le manager ne doit pas être affecté ici'
    assert_equal [terminer_intervention_path(@fille), :post, nil], terminer_destination(@fille)
  end

  test 'une intervention ordinaire, hors pointage, mène à `terminer` en POST' do
    self.current_user = users(:bond)
    intervention = interventions(:tonte_locaux)

    assert_nil intervention.template_slug
    assert_equal [terminer_intervention_path(intervention), :post, nil], terminer_destination(intervention)
  end

  test 'un pointage dont l’intervention modèle est introuvable se replie sur `terminer` plutôt que sur un lien vers nil' do
    self.current_user = @agent
    @fille.update_columns(template_slug: SecureRandom.uuid)

    assert_equal [terminer_intervention_path(@fille), :post, nil], terminer_destination(@fille)
  end

  test 'un pointage sans date de début renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.update_columns(début: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test 'un pointage sans date de fin renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.update_columns(fin: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test "un pointage de l'utilisateur reste dirigé vers `pointer` même sans date de fin" do
    self.current_user = @agent
    @fille.update_columns(fin: nil)

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  test 'un pointage resté ouvert un jour précédent renvoie vers le formulaire, pas vers `pointer`' do
    self.current_user = @agent
    @fille.update_columns(début: 5.days.ago, fin: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test 'le bouton Terminer ouvre le modal via l’ID du dialogue' do
    intervention = interventions(:tonte_locaux)

    assert_equal "document.getElementById('terminer_modal_#{intervention.id}').showModal()", js_ouvrir_modal_terminer(intervention)
    assert_equal "terminer_modal_#{intervention.id}", modal_id_terminer(intervention)
  end

  test 'un pointage sans agent renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.agents.destroy_all

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille.reload)
  end

  # Cette branche était inatteignable tant que le modèle posait une pause à 0 à chaque
  # sauvegarde : 0 n'est pas `blank?`, donc la pause n'était jamais réclamée.
  test 'un pointage sans temps de pause renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.update_columns(temps_de_pause: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille.reload)
  end

  test 'le message de terminaison nomme les dates manquantes' do
    intervention = interventions(:tonte_locaux)
    intervention.update_columns(début: nil, fin: nil)

    assert_equal 'La date de début et la date de fin sont obligatoires pour terminer cette intervention.',
                 message_terminaison_incomplete(intervention)
  end

  test "le message nomme l'agent manquant" do
    intervention = interventions(:tonte_locaux)
    intervention.agents.destroy_all

    assert_equal 'Au moins un agent est obligatoire pour terminer cette intervention.',
                 message_terminaison_incomplete(intervention.reload)
  end

  test 'aucun message de terminaison n’est renvoyé quand tout est renseigné' do
    assert_nil message_terminaison_incomplete(interventions(:tonte_locaux))
  end

  # --- Trajet ---
  # Le stub WebMock global renvoie une réponse sans `routes_info` : le bloc
  # Trajet de la fiche d'intervention n'est jamais rendu en `:texte` ni en
  # `:vide` par le reste de la suite.

  test 'un trajet enregistré suffit à afficher le bloc Trajet en texte' do
    @fille.trajet = '12 km aller-retour'

    assert_equal :texte, trajet_mode(@fille, nil)
  end

  test 'sans trajet enregistré, la réponse Routes suffit à afficher le bloc Trajet en texte' do
    @fille.trajet = nil

    assert_equal :texte, trajet_mode(@fille, { 'routes_info' => '8 km aller-retour' })
  end

  test 'sans trajet ni réponse Routes, le bloc Trajet est vide' do
    @fille.trajet = nil

    assert_equal :vide, trajet_mode(@fille, nil)
  end

  test 'le trajet enregistré prime sur la réponse Routes dans le texte affiché' do
    @fille.trajet = '12 km aller-retour'

    assert_equal '12 km aller-retour', trajet_texte(@fille, { 'routes_info' => '8 km aller-retour' })
  end

  test 'sans trajet enregistré, le texte affiché est celui de la réponse Routes' do
    @fille.trajet = nil

    assert_equal '8 km aller-retour', trajet_texte(@fille, { 'routes_info' => '8 km aller-retour' })
  end
end
