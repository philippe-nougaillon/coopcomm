# frozen_string_literal: true

require 'test_helper'

class AgentWorkflowStateInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(agent_paris, intervention_paris)
  end

  # Terminer
  test 'should get terminer' do
    assert @policy.terminer?
  end

  # Valider
  test "should'nt get valider" do
    refute @policy.valider?
  end

  # Refuser : interdit à l'agent même s'il est affecté à l'intervention.
  test "should'nt get refuser" do
    refute @policy.refuser?
  end

  # Archiver : réservé aux manager/administrateur.
  test "should'nt get archiver" do
    refute @policy.archiver?
  end
end
