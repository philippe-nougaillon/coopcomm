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

  test 'index / new / services_for_adherent autorisés pour un administrateur' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.services_for_adherent?
  end

  test 'show / update / destroy / create autorisés dans son organisation' do
    assert @policy.show?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.create?
  end

  test "accès interdit sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.create?
  end

  test "scope : un administrateur voit les conventions de son organisation, pas celles d'une autre" do
    scope = ConventionPolicy::Scope.new(@administrateur, Convention.all).resolve
    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
