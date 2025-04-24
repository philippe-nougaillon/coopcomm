require "test_helper"

class AgentWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_marseille = users(:agent_marseille)
    
    intervention_paris = interventions(:intervention_paris)

    @wrongPolicy = ToolPolicy.new(agent_marseille, intervention_paris)
  end

  test "should refute show with wrong organisation" do
    refute @wrongPolicy.show?
  end
end