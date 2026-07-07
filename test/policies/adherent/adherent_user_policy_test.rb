# frozen_string_literal: true

require 'test_helper'

class AdherentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    user_paris = users(:user_paris)

    @policy = UserPolicy.new(adherent_paris, user_paris)
    @policy_user_myself = UserPolicy.new(adherent_paris, adherent_paris)
  end

  # Index
  test 'accès adhérent user index interdit' do
    refute @policy.index?
  end

  # Show
  test 'accès adhérent user show interdit' do
    refute @policy.show?
  end

  test 'accès autorisé pour un adhérent sur sa page show' do
    assert @policy_user_myself.show?
  end

  # New
  test 'accès adhérent user new interdit' do
    refute @policy.new?
  end

  # Create
  test 'accès adhérent user create interdit' do
    refute @policy.create?
  end

  # Edit
  test 'accès adhérent user edit interdit' do
    refute @policy.edit?
  end

  # Update
  test 'accès adhérent user update interdit' do
    refute @policy.update?
  end

  # Destroy
  test 'accès adhérent user destroy interdit' do
    refute @policy.destroy?
  end

  # Agent calendrier
  test 'accès adhérent user agent calendrier interdit' do
    refute @policy.agent_calendrier?
  end

  # Inviter
  test "accès interdit pour un adherent sur la page inviter d'un user" do
    refute @policy.inviter?
  end

  # Edit password
  test 'accès autorisé pour un adherent sur sa page edit_password' do
    assert @policy_user_myself.edit_password?
  end

  # Update password
  test 'accès autorisé pour un adherent sur sa page update_password' do
    assert @policy_user_myself.update_password?
  end

  # Reactivate
  test "accès interdit pour un adherent sur la page reactivate d'un user" do
    refute @policy.reactivate?
  end
end
