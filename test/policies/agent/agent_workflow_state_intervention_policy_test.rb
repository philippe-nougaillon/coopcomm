require "test_helper"

class AgentWorkflowStateInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)
    
    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(agent_paris, intervention_paris)
  end

  # Terminer
  test "should get terminer" do
    assert @policy.terminer?
  end

  # Valider
  test "should'nt get valider" do
    refute @policy.valider?
  end

  # Refuser
  test "should'nt get refuser" do
    refute @policy.refuser?
  end

  # Archiver
  test "should get archiver" do
    assert @policy.archiver?
  end
end
