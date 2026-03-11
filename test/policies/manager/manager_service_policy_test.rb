require "test_helper"

class ManagerServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    service = services(:comptabilite)
    service_different = services(:technique)

    @policy = ServicePolicy.new(manager, service)
    @policy_service_different = ServicePolicy.new(manager, service_different)
  end

  # Index
  test "accès autorisé pour un manager sur la page index des services" do
    assert @policy.index?
  end

  # Show
  test "accès autorisé pour un manager sur la page show d'un service" do
    assert @policy.show?
  end

  test "accès interdit pour un manager sur la page show d'un service qui ne lui appartient pas" do
    refute @policy_service_different.show?
  end

  # New
  test "accès autorisé pour un manager sur la page new d'un service" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un manager sur la page create d'un service" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un manager sur la page edit d'un service" do
    assert @policy.edit?
  end

  test "accès interdit pour un manager sur la page edit d'un service qui ne lui appartient pas" do
    refute @policy_service_different.edit?
  end

  # Update
  test "accès autorisé pour un manager sur la page update d'un service" do
    assert @policy.update?
  end

  test "accès interdit pour un manager sur la page update d'un service qui ne lui appartient pas" do
    refute @policy_service_different.update?
  end

  # Destroy
  test "accès autorisé pour un manager sur la page destroy d'un service" do
    assert @policy.destroy?
  end

  test "accès interdit pour un manager sur la page destroy d'un service qui ne lui appartient pas" do
    refute @policy_service_different.destroy?
  end
end
