# frozen_string_literal: true

require 'test_helper'

class AgentFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @agent = users(:martin_technique_paris)

    facture = factures(:facture_paris)

    @policy = FacturePolicy.new(@agent, facture)
  end

  test 'accès interdit pour un agent sur une facture de son organisation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.pdf?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.refuser?
  end

  test 'scope : un agent ne voit aucune facture' do
    assert_empty FacturePolicy::Scope.new(@agent, Facture.all).resolve
  end
end
