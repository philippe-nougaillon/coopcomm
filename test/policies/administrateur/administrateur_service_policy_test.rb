require "test_helper"

class AdministrateurServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)
    service = services(:service_paris)
    service_different = services(:service_marseille)

    @policy = ServicePolicy.new(administrateur, service)
    @policy_service_different = ServicePolicy.new(administrateur, service_different)
  end

  # Index
  test "accès autorisé pour un administrateur sur la page index des services" do
    assert @policy.index?
  end

  # Show
  test "accès autorisé pour un administrateur sur la page show d'un service" do
    assert @policy.show?
  end

  test "accès interdit pour un administrateur sur la page show d'un service d'une autre organisation" do
    refute @policy_service_different.show?
  end

  # New
  test "accès autorisé pour un administrateur sur la page new d'un service" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un administrateur sur la page create d'un service" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un administrateur sur la page edit d'un service" do
    assert @policy.edit?
  end

  test "accès interdit pour un administrateur sur la page edit d'un service d'une autre organisation" do
    refute @policy_service_different.edit?
  end

  # Update
  test "accès autorisé pour un administrateur sur la page update d'un service" do
    assert @policy.update?
  end

  test "accès interdit pour un administrateur sur la page update d'un service d'une autre organisation" do
    refute @policy_service_different.update?
  end

  # Destroy
  test "accès autorisé pour un administrateur sur la page destroy d'un service" do
    assert @policy.destroy?
  end

  test "accès interdit pour un administrateur sur la page destroy d'un service d'une autre organisation" do
    refute @policy_service_different.destroy?
  end
end
