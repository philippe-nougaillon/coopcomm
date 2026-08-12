# frozen_string_literal: true

require 'test_helper'

class AdherentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    user = users(:user_paris)

    @policy = UserPolicy.new(adherent, user)
    @policy_user_myself = UserPolicy.new(adherent, adherent)
  end

  test 'accès interdit pour un adhérent sur un user de son organisation' do
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

  test 'accès autorisé pour un adhérent sur sa propre fiche' do
    assert @policy_user_myself.show?
    assert @policy_user_myself.edit?
    assert @policy_user_myself.update?
    assert @policy_user_myself.edit_password?
    assert @policy_user_myself.update_password?
  end

  test 'accès interdit pour un adhérent sur sa propre fiche' do
    refute @policy_user_myself.destroy?
    refute @policy_user_myself.inviter?
    refute @policy_user_myself.reactivate?
  end
end
