# frozen_string_literal: true

require 'test_helper'

class AgentOrganisationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    organisation = organisations(:mairie_paris)

    @policy = OrganisationPolicy.new(agent, organisation)
  end

  test 'accès interdit pour un agent sur son organisation' do
    refute @policy.show?
    refute @policy.update?
    refute @policy.destroy?
  end
end
