# frozen_string_literal: true

require 'test_helper'

class AgentInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(agent_paris, intervention_paris)
  end

  # Index
  test 'should get index' do
    assert @policy.index?
  end

  # Show
  test 'should get show' do
    assert @policy.show?
  end

  # New
  test 'should get new' do
    assert @policy.new?
  end

  # Create
  test 'should get create' do
    assert @policy.create?
  end

  # Edit
  test 'should get edit' do
    assert @policy.edit?
  end

  # Update
  test 'should get update' do
    assert @policy.update?
  end

  # Destroy
  test 'should refute destroy with agent' do
    refute @policy.destroy?
  end

  # Purge
  test 'should get purge' do
    assert @policy.purge?
  end

  # Get_unavailable_elements
  test 'should get get_unavailable_elements' do
    assert @policy.get_unavailable_elements?
  end
end
