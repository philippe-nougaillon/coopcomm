# frozen_string_literal: true

require 'test_helper'

class AgentAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    @policy = AdminPolicy.new(agent, :admin)
  end

  test "accès interdit pour un agent sur l'espace admin" do
    refute @policy.audits?
    refute @policy.create_new_user?
    refute @policy.create_new_user_do?
    refute @policy.parametres?
    refute @policy.stats?
  end
end
