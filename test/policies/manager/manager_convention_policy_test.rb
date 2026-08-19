# frozen_string_literal: true

require 'test_helper'

class ManagerConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo)

    convention = conventions(:convention_paris)
    convention_autre_org = conventions(:convention_marseille)

    @policy = ConventionPolicy.new(@manager, convention)
    @policy_autre_service = ConventionPolicy.new(users(:manager_paris), convention)
    @policy_autre_org = ConventionPolicy.new(@manager, convention_autre_org)
  end

  test 'accès autorisé pour un manager sur une convention de son service' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.services_for_adherent?
    assert @policy.show?
    assert @policy.destroy?
    assert @policy.edit?
    assert @policy.update?
  end

  test "accès interdit pour un manager sur une convention d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.edit?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
  end

  test "accès interdit pour un manager sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end

  test "scope : un manager ne voit que les conventions des services qu'il gère" do
    scope = ConventionPolicy::Scope.new(@manager, Convention.all).resolve

    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
