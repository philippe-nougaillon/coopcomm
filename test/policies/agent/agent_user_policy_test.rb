# frozen_string_literal: true

require 'test_helper'

class AgentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    user = users(:user_paris)

    @policy = UserPolicy.new(agent, user)
    @policy_user_myself = UserPolicy.new(agent, agent)
  end

  test "accès interdit pour un agent sur un user de son organisation" do
    refute @policy.index?
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.inviter?
    refute @policy.reactivate?
    refute @policy.agent_calendrier?
    refute @policy.import?
    refute @policy.import_do?
    refute @policy.edit_password?
    refute @policy.update_password?
  end

  test 'accès autorisé pour un agent sur sa propre fiche' do
    assert @policy_user_myself.show?
    assert @policy_user_myself.edit?
    assert @policy_user_myself.update?
    assert @policy_user_myself.edit_password?
    assert @policy_user_myself.update_password?
  end

  test 'accès interdit pour un agent sur sa propre fiche' do
    refute @policy_user_myself.destroy?
    refute @policy_user_myself.inviter?
    refute @policy_user_myself.reactivate?
  end
end
