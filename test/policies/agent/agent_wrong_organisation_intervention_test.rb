# frozen_string_literal: true

require 'test_helper'

class AgentWrongOrganisationInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_marseille = users(:agent_marseille)

    intervention_paris = interventions(:intervention_paris)

    @wrongPolicy = InterventionPolicy.new(agent_marseille, intervention_paris)
  end

  test 'should refute show with wrong organisation' do
    refute @wrongPolicy.show?
  end

  test 'should refute edit with wrong organisation' do
    refute @wrongPolicy.edit?
  end

  test 'should refute update with wrong organisation' do
    refute @wrongPolicy.update?
  end

  test 'should refute purge with wrong organisation' do
    refute @wrongPolicy.purge?
  end

  test 'should refute terminer with wrong organisation' do
    refute @wrongPolicy.terminer?
  end

  test 'should refute valider with wrong organisation' do
    refute @wrongPolicy.valider?
  end

  test 'should refute refuser with wrong organisation' do
    refute @wrongPolicy.refuser?
  end

  test 'should refute archiver with wrong organisation' do
    refute @wrongPolicy.archiver?
  end
end
