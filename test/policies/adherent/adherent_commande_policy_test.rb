# frozen_string_literal: true

require 'test_helper'

class AdherentCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @commande = commandes(:commande_paris)
  end

  test "un adhérent a accès à l'index des commandes" do
    policy = CommandePolicy.new(@adherent, @commande)
    assert policy.index?
  end

  test "un adhérent voit le détail de ses propres commandes quel que soit l'état" do
    @commande.update!(adherent_id: @adherent.id, workflow_state: 'envoyé')
    policy = CommandePolicy.new(@adherent, @commande)
    assert policy.show?
  end

  test "un adhérent ne voit pas le détail de ses propres commandes à l'état créé" do
    @commande.update!(adherent_id: @adherent.id, workflow_state: 'créé')
    policy = CommandePolicy.new(@adherent, @commande)
    refute policy.show?
  end

  test "un adhérent n'a pas accès aux commandes d'un autre adhérent" do
    autre_adherent = users(:patrick_adherent_paris)
    @commande.update!(adherent_id: autre_adherent.id, workflow_state: 'envoyé')
    policy = CommandePolicy.new(@adherent, @commande)
    refute policy.show?
  end

  test "un agent n'a aucun accès aux commandes" do
    policy = CommandePolicy.new(@agent, @commande)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.create_facture?
  end

  # Décision : le Scope des commandes est un pass-through volontaire (il ne filtre PAS).
  test 'scope : un adhérent ne voit que ses propres commandes hors état créé' do
    scope = CommandePolicy::Scope.new(@adherent, Commande.all).resolve

    expected_ids = Commande.where(adherent_id: @adherent.id).where.not(workflow_state: 'créé').pluck(:id).sort
    assert_equal expected_ids, scope.pluck(:id).sort
  end
end