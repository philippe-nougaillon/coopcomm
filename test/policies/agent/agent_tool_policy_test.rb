# frozen_string_literal: true

require 'test_helper'

class AgentToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    tool = tools(:outil_paris)
    tool_autre_org = tools(:outil_marseille)

    @policy = ToolPolicy.new(agent, tool)
    @policy_autre_org = ToolPolicy.new(agent, tool_autre_org)
  end

  test 'accès autorisé pour un agent sur un outil de son organisation' do
    assert @policy.index?
    assert @policy.show?
  end

  test 'accès interdit pour un agent sur un outil de son organisation' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test "accès interdit pour un agent sur un outil d'une autre organisation" do
    refute @policy_autre_org.show?
  end
end
