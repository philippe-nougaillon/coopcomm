# frozen_string_literal: true

require 'test_helper'

class AdherentToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    tool = tools(:outil_paris)

    @policy = ToolPolicy.new(adherent, tool)
  end

  test 'accès interdit pour un adhérent sur un outil de son organisation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end
end
