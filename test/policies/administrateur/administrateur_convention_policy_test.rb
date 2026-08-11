# frozen_string_literal: true

require 'test_helper'

class AdministrateurConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris) # mairie_paris

    convention = conventions(:convention_paris)               # mairie_paris
    convention_autre_org = conventions(:convention_marseille) # mairie_marseille

    @policy = ConventionPolicy.new(@administrateur, convention)
    @policy_autre_org = ConventionPolicy.new(@administrateur, convention_autre_org)
  end

  test 'accès autorisé pour un administrateur sur une convention de son organisation' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.services_for_adherent?
    assert @policy.show?
    assert @policy.destroy?
  end

  test 'accès interdit pour un administrateur sur une convention de son organisation' do
    refute @policy.edit?
    refute @policy.update?
  end

  test "accès interdit pour un administrateur sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end

  test 'scope' do
    scope = ConventionPolicy::Scope.new(@administrateur, Convention.all).resolve

    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
