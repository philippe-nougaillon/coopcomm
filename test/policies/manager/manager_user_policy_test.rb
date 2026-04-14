require "test_helper"

class ManagerUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:manager_paris)
    
    user_paris = users(:bond)
    user_paris_service_different = users(:martin_technique_paris)

    @policy = UserPolicy.new(manager_paris, user_paris)
    @policy_user_myself = UserPolicy.new(manager_paris, manager_paris)
    @policy_services_differents = UserPolicy.new(manager_paris, user_paris_service_different)
    @policy_manager = UserPolicy.new(manager_paris, users(:hidalgo))
    @policy_administrateur = UserPolicy.new(manager_paris, users(:administrateur_paris))
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
    refute @policy_services_differents.show?
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
  test "accès autorisé pour un manager sur la page edit d'un agent" do
    assert @policy.edit?
  end

  test "accès interdit pour un manager sur la page edit d'un manager" do
    refute @policy_manager.edit?
  end

  test "accès interdit pour un manager sur la page edit d'un administrateur" do
    refute @policy_administrateur.edit?
  end

  # Update
  test "accès autorisé pour un manager sur la page update d'un user" do
    assert @policy.update?
  end

  test "accès interdit pour un manager sur la page update d'un user sans aucun service en commun avec le manager" do
    refute @policy_services_differents.update?
  end

  # Destroy
  test "accès autorisé pour un manager de supprimer un user" do
    assert @policy.destroy?
  end

  test "accès interdit pour un manager de supprimer un user sans aucun service en commun avec le manager" do
    refute @policy_services_differents.destroy?
  end

  test "accès interdit pour un manager de supprimer un manager" do
    refute @policy_manager.destroy?
  end

  test "accès interdit pour un manager de supprimer un administrateur" do
    refute @policy_administrateur.destroy?
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

  test "accès interdit pour un manager sur la page edit_password d'un autre user" do
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
    refute @policy_services_differents.reactivate?
  end
end
