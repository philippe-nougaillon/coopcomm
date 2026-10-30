# frozen_string_literal: true

require 'test_helper'

class AgentDashboardPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    @policy = DashboardPolicy.new(agent, nil)
  end

  test 'accès interdit pour un agent sur le tableau de bord' do
    refute @policy.index?
    refute @policy.reservations_du_jour?
  end
end
