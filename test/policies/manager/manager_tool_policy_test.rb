# frozen_string_literal: true

require 'test_helper'

class ManagerToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    tool = tools(:outil_paris)
    tool_autre_org = tools(:outil_marseille)

    @policy = ToolPolicy.new(manager, tool)
    @policy_autre_org = ToolPolicy.new(manager, tool_autre_org)
  end

  test 'accès autorisé pour un manager sur un outil de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès interdit pour un manager sur un outil d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
