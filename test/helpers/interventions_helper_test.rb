# frozen_string_literal: true

require 'test_helper'

# `terminer_destination` donne au bouton « Terminer » la même destination sur la
# home, l'index et le show : une intervention issue d'un pointage se termine par
# l'action `pointer` de l'intervention modèle (qui pose la fin réelle et
# recalcule le temps), pas par `terminer` (qui ne change que l'état).
#
# Le discriminant est l'AFFECTATION, pas le rôle : un manager ou un
# administrateur peut être choisi comme agent d'une intervention.
class InterventionsHelperTest < ActionView::TestCase
  # Le helper interroge `current_user`, fourni par le contrôleur en temps normal.
  attr_accessor :current_user

  setup do
    @mère  = interventions(:intervention_repete) # agents de fixture : bond, martin
    @fille = interventions(:intervention_fille)
    @fille.update_columns(template_slug: @mère.slug)
  end

  test "affecté à l'intervention modèle : on passe par `pointer` de ce modèle" do
    self.current_user = users(:bond)

    assert_equal [pointer_intervention_path(@mère), :get], terminer_destination(@fille)
  end

  test 'manager affecté comme agent : même traitement que les autres affectés' do
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: @mère)
    self.current_user = manager

    assert_equal [pointer_intervention_path(@mère), :get], terminer_destination(@fille)
  end

  test 'non affecté à l\'intervention modèle : `terminer` en POST' do
    self.current_user = users(:manager_paris)

    assert_not @mère.agents.include?(current_user), 'garde : le manager ne doit pas être affecté ici'
    assert_equal [terminer_intervention_path(@fille), :post], terminer_destination(@fille)
  end

  test 'intervention ordinaire (hors pointage) : `terminer` en POST' do
    self.current_user = users(:bond)
    intervention = interventions(:tonte_locaux)

    assert_nil intervention.template_slug
    assert_equal [terminer_intervention_path(intervention), :post], terminer_destination(intervention)
  end

  test 'intervention modèle introuvable : repli sur `terminer` plutôt qu un lien vers nil' do
    self.current_user = users(:bond)
    @fille.update_columns(template_slug: SecureRandom.uuid)

    assert_equal [terminer_intervention_path(@fille), :post], terminer_destination(@fille)
  end
end
