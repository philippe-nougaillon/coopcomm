# frozen_string_literal: true

require 'test_helper'

class AgentPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @agent = users(:martin_technique_paris)

    prestation = prestations(:nettoyage_bureaux)

    @policy = PrestationPolicy.new(@agent, prestation)
  end

  test 'accès interdit pour un agent sur une prestation de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test 'scope : un agent ne voit que les prestations de son organisation' do
    scope = PrestationPolicy::Scope.new(@agent, Prestation.all).resolve

    assert_includes scope, prestations(:nettoyage_bureaux)
    refute_includes scope, prestations(:prestation_marseille)
  end
end
