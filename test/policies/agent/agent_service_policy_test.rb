# frozen_string_literal: true

require 'test_helper'

class AgentServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    service = services(:service_paris)

    @policy = ServicePolicy.new(agent, service)
  end

  test 'accès interdit pour un agent sur un service de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end
end
