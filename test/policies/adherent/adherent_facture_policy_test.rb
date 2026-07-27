# frozen_string_literal: true

require 'test_helper'

# Rôles sans aucun droit de gestion des factures (adhérent et agent regroupés).
class AdherentFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @facture = factures(:facture_paris)
  end

  test "un adhérent voit le détail de ses propres factures quel que soit l'état" do
    @facture.update!(adherent_id: @adherent.id, workflow_state: 'envoyé')
    policy = FacturePolicy.new(@adherent, @facture)
    assert policy.show?
  end

  test "un adhérent ne voit pas le détail de ses propres factures à l'état créé" do
    @facture.update!(adherent_id: @adherent.id, workflow_state: 'créé')
    policy = FacturePolicy.new(@adherent, @facture)
    refute policy.show?
  end

  test "un adhérent n'a pas accès aux factures d'un autre adhérent" do
    autre_adherent = users(:patrick_adherent_paris)
    @facture.update!(adherent_id: autre_adherent.id, workflow_state: 'envoyé')
    policy = FacturePolicy.new(@adherent, @facture)
    refute policy.show?
  end

  test "un agent n'a aucun accès aux factures" do
    policy = FacturePolicy.new(@agent, @facture)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
  end
end
