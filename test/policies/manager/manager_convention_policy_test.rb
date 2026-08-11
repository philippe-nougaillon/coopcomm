# frozen_string_literal: true

require 'test_helper'

class ManagerConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo) # gère service_paris, informatique et technique

    convention_gérée = conventions(:convention_paris)         # service informatique → géré par hidalgo
    convention_autre_org = conventions(:convention_marseille) # mairie_marseille

    @policy = ConventionPolicy.new(@manager, convention_gérée)
    @policy_autre_org = ConventionPolicy.new(@manager, convention_autre_org)
    # manager_paris (même organisation) ne gère pas le service informatique
    @policy_service_non_géré = ConventionPolicy.new(users(:manager_paris), convention_gérée)
  end

  test 'index / new autorisés pour un manager' do
    assert @policy.index?
    assert @policy.new?
  end

  test 'show / destroy / create autorisés sur une convention de son service, update jamais' do
    assert @policy.show?
    refute @policy.edit?
    refute @policy.update?
    assert @policy.destroy?
    assert @policy.create?
  end

  test "accès interdit sur une convention d'un service qu'il ne gère pas (même organisation)" do
    refute @policy_service_non_géré.show?
    refute @policy_service_non_géré.update?
    refute @policy_service_non_géré.destroy?
    refute @policy_service_non_géré.create?
  end

  test "accès interdit sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.create?
  end

  test "scope : un manager ne voit que les conventions des services qu'il gère" do
    scope = ConventionPolicy::Scope.new(@manager, Convention.all).resolve
    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
