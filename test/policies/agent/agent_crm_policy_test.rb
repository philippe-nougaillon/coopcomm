# frozen_string_literal: true

require 'test_helper'

class AgentCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    @policy = CrmPolicy.new(agent, :crm)
  end

  test 'accès interdit pour un agent sur le CRM' do
    refute @policy.index?
  end
end
