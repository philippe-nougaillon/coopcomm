# frozen_string_literal: true

require 'test_helper'

class AgentCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @agent = users(:martin_technique_paris)

    cotation = cotations(:cotation_paris)

    @policy = CotationPolicy.new(@agent, cotation)
  end

  test 'accès interdit pour un agent sur une cotation de son organisation' do
    refute @policy.index?
    refute @policy.new?
    refute @policy.create?
    refute @policy.show?
    refute @policy.pdf?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.refuser?
    refute @policy.create_commande?
    refute @policy.signer?
    refute @policy.signer_do?
  end

  test 'scope : un agent ne voit aucune cotation' do
    assert_empty CotationPolicy::Scope.new(@agent, Cotation.all).resolve
  end
end
