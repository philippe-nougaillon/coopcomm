require "test_helper"

class ManagerUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)
    
    user_paris = users(:bond)
    user_paris_service_different = users(:martin_technique_paris)

    @policy = UserPolicy.new(manager_paris, user_paris)
    @policy_user_myself = UserPolicy.new(manager_paris, manager_paris)
    @policy_organisation_differente = UserPolicy.new(manager_paris, user_paris_service_different)
  end

  # Index
  test "accès autorisé pour un manager sur la page index des users" do
    assert @policy.index?
  end

  # Show
  test "accès autorisé pour un manager sur la page show d'un user" do
    assert @policy.show?
  end

  test "accès interdit pour un manager sur la page show d'un user sans aucun service en commun avec le manager" do
    refute @policy_organisation_differente.show?
  end

  # New
  test "accès autorisé pour un manager sur la page new d'un user" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un manager sur la page create d'un user" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un manager sur la page edit d'un user" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un manager sur la page update d'un user" do
    assert @policy.update?
  end

  test "accès interdit pour un manager sur la page update d'un user sans aucun service en commun avec le manager" do
    refute @policy_organisation_differente.update?
  end

  # Destroy
  test "accès autorisé pour un manager sur la page destroy d'un user" do
    assert @policy.destroy?
  end

  test "accès interdit pour un manager sur la page destroy d'un user sans aucun service en commun avec le manager" do
    refute @policy_organisation_differente.destroy?
  end

  # agent calendrier
  test "accès autorisé pour un manager sur la page agent_calendrier" do
    assert @policy.agent_calendrier?
  end

  # Inviter
  test "accès interdit pour un manager sur la page inviter d'un user" do
    assert @policy.inviter?
  end

  # Edit password
  test "accès autorisé pour un manager sur sa page edit_password" do
    assert @policy_user_myself.edit_password?
  end

  test "accès interdit pour un manager sur sa page edit_password d'un autre user" do
    refute @policy.edit_password?
  end

  # Update password
  test "accès autorisé pour un manager sur sa page update_password" do
    assert @policy_user_myself.update_password?
  end

  test "accès interdit pour un manager sur sa page update_password d'un autre user" do
    refute @policy.update_password?
  end

  # Reactivate
  test "accès autorisé pour un manager sur la page reactivate d'un user" do
    assert @policy.reactivate?
  end

  test "accès interdit pour un manager sur la page reactivate d'un user d'une autre organisation" do
    refute @policy_organisation_differente.reactivate?
  end
end
