# frozen_string_literal: true

require 'test_helper'

# `terminer_destination` donne au bouton « Terminer » la même destination sur la home.
class InterventionsHelperTest < ActionView::TestCase
  # Le helper interroge `current_user`, fourni par le contrôleur en temps normal.
  attr_accessor :current_user

  setup do
    @mère  = interventions(:intervention_repete) # agents de fixture : bond, martin
    @fille = interventions(:intervention_fille)
    @fille.update_columns(template_slug: @mère.slug, fin: 1.hour.ago)
  end

  test "affecté à l'intervention modèle : on passe par `pointer` de ce modèle" do
    self.current_user = users(:bond)

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  test 'manager affecté comme agent : même traitement que les autres affectés' do
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: @mère)
    self.current_user = manager

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  test 'non affecté à l\'intervention modèle : `terminer` en POST' do
    self.current_user = users(:manager_paris)

    assert_not @mère.agents.include?(current_user), 'garde : le manager ne doit pas être affecté ici'
    assert_equal [terminer_intervention_path(@fille), :post, nil], terminer_destination(@fille)
  end

  test 'intervention ordinaire (hors pointage) : `terminer` en POST' do
    self.current_user = users(:bond)
    intervention = interventions(:tonte_locaux)

    assert_nil intervention.template_slug
    assert_equal [terminer_intervention_path(intervention), :post, nil], terminer_destination(intervention)
  end

  test 'intervention modèle introuvable : repli sur `terminer` plutôt qu un lien vers nil' do
    self.current_user = users(:bond)
    @fille.update_columns(template_slug: SecureRandom.uuid)

    assert_equal [terminer_intervention_path(@fille), :post, nil], terminer_destination(@fille)
  end

  test 'sans date de début : renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.update_columns(début: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test 'sans date de fin : renvoie vers le formulaire avec la demande de terminaison' do
    self.current_user = users(:manager_paris)
    @fille.update_columns(fin: nil)

    assert_equal [edit_intervention_path(@fille), :get, { terminer: 1 }], terminer_destination(@fille)
  end

  test "un pointage de l'utilisateur reste dirigé vers `pointer` même sans date de fin" do
    self.current_user = users(:bond)
    @fille.update_columns(fin: nil)

    assert_equal [pointer_intervention_path(@mère), :get, nil], terminer_destination(@fille)
  end

  test 'le bouton Terminer ouvre le modal via l’ID du dialogue' do
    intervention = interventions(:tonte_locaux)

    assert_equal "document.getElementById('terminer_modal_#{intervention.id}').showModal()", js_ouvrir_modal_terminer(intervention)
    assert_equal "terminer_modal_#{intervention.id}", modal_id_terminer(intervention)
  end

  test 'le helper renvoie le message de dates manquantes quand il faut terminer' do
    intervention = interventions(:tonte_locaux)
    intervention.update_columns(début: nil, fin: nil)

    assert_equal 'Les dates de début et de fin sont obligatoires pour terminer cette intervention.', message_dates_manquantes(intervention)
  end
end
