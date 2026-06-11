# frozen_string_literal: true

require 'test_helper'

class ManagerWorkflowStateInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)

    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(manager_paris, intervention_paris)
  end

  # Terminer
  test 'should get terminer' do
    assert @policy.terminer?
  end

  # Valider
  test 'should get valider' do
    assert @policy.valider?
  end

  # Refuser
  test 'should get refuser' do
    assert @policy.refuser?
  end

  # Archiver
  test 'should get archiver' do
    assert @policy.archiver?
  end
end
