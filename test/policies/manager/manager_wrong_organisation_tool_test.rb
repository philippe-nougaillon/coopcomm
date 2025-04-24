require "test_helper"

class ManagerWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_marseille = users(:manager_marseille)
    
    intervention_paris = interventions(:intervention_paris)

    @wrongPolicy = ToolPolicy.new(manager_marseille, intervention_paris)
  end

  test "should refute show with wrong organisation" do
    refute @wrongPolicy.show?
  end
end