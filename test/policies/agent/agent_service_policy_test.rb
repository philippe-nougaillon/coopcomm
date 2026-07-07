# frozen_string_literal: true

require 'test_helper'

class AgentServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)

    service = services(:service_paris)
    service_different = services(:service_marseille)

    @policy = ServicePolicy.new(agent, service)
    @policy_service_different = ServicePolicy.new(agent, service_different)
  end

  # Index
  test 'accès interdit pour un agent sur la page index des services' do
    refute @policy.index?
  end

  # Show
  test "accès interdit pour un agent sur la page show d'un service" do
    refute @policy.show?
  end

  test "accès interdit pour un agent sur la page show d'un service qui ne lui appartient pas" do
    refute @policy_service_different.show?
  end

  # New
  test "accès interdit pour un agent sur la page new d'un service" do
    refute @policy.new?
  end

  # Create
  test "accès interdit pour un agent sur la page create d'un service" do
    refute @policy.create?
  end

  # Edit
  test "accès interdit pour un agent sur la page edit d'un service" do
    refute @policy.edit?
  end

  # Update
  test "accès interdit pour un agent sur la page update d'un service" do
    refute @policy.update?
  end

  test "accès interdit pour un agent sur la page update d'un service qui ne lui appartient pas" do
    refute @policy_service_different.update?
  end

  # Destroy
  test "accès interdit pour un agent sur la page destroy d'un service" do
    refute @policy.destroy?
  end

  test "accès interdit pour un agent sur la page destroy d'un service qui ne lui appartient pas" do
    refute @policy_service_different.destroy?
  end
end
