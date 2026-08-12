# frozen_string_literal: true

require 'test_helper'

class AdministrateurToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    tool = tools(:outil_paris)
    tool_autre_org = tools(:outil_marseille)

    @policy = ToolPolicy.new(administrateur, tool)
    @policy_autre_org = ToolPolicy.new(administrateur, tool_autre_org)
  end

  test 'accès autorisé pour un administrateur sur un outil de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès interdit pour un administrateur sur un outil d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
