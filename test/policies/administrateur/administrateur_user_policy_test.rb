require "test_helper"

class AdministrateurUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)
    
    user_paris = users(:bond)
    user_marseille_service_different = users(:agent_marseille)

    @policy = UserPolicy.new(administrateur_paris, user_paris)
    @policy_service_different = UserPolicy.new(administrateur_paris, user_marseille_service_different)
  end

  # Index
  test "accès autorisé pour un administrateur sur la page index des users" do
    assert @policy.index?
  end

  # Show
  test "accès autorisé pour un administrateur sur la page show d'un user" do
    assert @policy.show?
  end

  test "accès interdit pour un administrateur sur la page show d'un user d'une autre organisation" do
    refute @policy_service_different.show?
  end

  # New
  test "accès autorisé pour un administrateur sur la page new d'un user" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un administrateur sur la page create d'un user" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un administrateur sur la page edit d'un user" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un administrateur sur la page update d'un user" do
    assert @policy.update?
  end

  test "accès interdit pour un administrateur sur la page update d'un user d'une autre organisation" do
    refute @policy_service_different.update?
  end

  # Destroy
  test "accès autorisé pour un administrateur sur la page destroy d'un user" do
    assert @policy.destroy?
  end

  test "accès interdit pour un administrateur sur la page destroy d'un user d'une autre organisation" do
    refute @policy_service_different.destroy?
  end

  # agent calendrier
  test "accès autorisé pour un administrateur sur la page agent_calendrier" do
    assert @policy.agent_calendrier?
  end
end
