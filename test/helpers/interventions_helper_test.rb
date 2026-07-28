# frozen_string_literal: true

require 'test_helper'

# `terminer_destination` aligne le bouton « Terminer » de l'index et du show sur
# celui de la page d'accueil : pour un agent, une intervention issue d'un
# pointage se termine par l'action `pointer` de l'intervention modèle (qui pose
# la fin réelle et recalcule le temps), pas par l'action `terminer` (qui ne
# change que l'état).
class InterventionsHelperTest < ActionView::TestCase
  # Le helper interroge `current_user`, fourni par le contrôleur en temps normal.
  attr_accessor :current_user

  setup do
    @mère  = interventions(:intervention_repete)
    @fille = interventions(:intervention_fille)
    @fille.update_columns(template_slug: @mère.slug)
  end

  test "agent sur une intervention de pointage : on passe par `pointer` de l'intervention modèle" do
    self.current_user = users(:bond)

    assert_equal [pointer_intervention_path(@mère), :get], terminer_destination(@fille)
  end

  test 'agent sur une intervention ordinaire : `terminer` en POST' do
    self.current_user = users(:bond)
    intervention = interventions(:tonte_locaux)

    assert_nil intervention.template_slug
    assert_equal [terminer_intervention_path(intervention), :post], terminer_destination(intervention)
  end

  test 'manager sur une intervention de pointage : `terminer` en POST (il ne pointe pas)' do
    self.current_user = users(:manager_paris)

    assert_equal [terminer_intervention_path(@fille), :post], terminer_destination(@fille)
  end

  test 'intervention modèle introuvable : repli sur `terminer` plutôt qu un lien vers nil' do
    self.current_user = users(:bond)
    @fille.update_columns(template_slug: SecureRandom.uuid)

    assert_equal [terminer_intervention_path(@fille), :post], terminer_destination(@fille)
  end
end
