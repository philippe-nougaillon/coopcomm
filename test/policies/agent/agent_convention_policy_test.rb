# frozen_string_literal: true

require 'test_helper'

class AgentConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @agent = users(:martin_technique_paris)

    convention = conventions(:convention_paris)

    @policy = ConventionPolicy.new(@agent, convention)
  end

  test 'accès interdit pour un agent sur une convention de son organisation' do
    refute @policy.index?
    refute @policy.new?
    refute @policy.create?
    refute @policy.services_for_adherent?
    refute @policy.show?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test 'scope : un agent ne voit aucune convention' do
    assert_empty ConventionPolicy::Scope.new(@agent, Convention.all).resolve
  end
end
