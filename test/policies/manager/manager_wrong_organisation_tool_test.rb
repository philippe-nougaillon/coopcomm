require "test_helper"

class ManagerWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_marseille = users(:manager_marseille)
    
    tool_paris = tools(:outil_paris)

    @wrongPolicy = ToolPolicy.new(manager_marseille, tool_paris)
  end

  test "should refute show with wrong organisation" do
    refute @wrongPolicy.show?
  end
end