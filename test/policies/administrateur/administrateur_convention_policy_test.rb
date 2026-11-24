# frozen_string_literal: true

require 'test_helper'

class AdministrateurConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris)

    convention = conventions(:convention_paris)
    convention_autre_org = conventions(:convention_marseille)

    @policy = ConventionPolicy.new(@administrateur, convention)
    @policy_analyse = ConventionPolicy.new(@administrateur, conventions(:analyse_de_weil))
    @policy_autre_org = ConventionPolicy.new(@administrateur, convention_autre_org)
    @policy_analyse_autre_org = ConventionPolicy.new(@administrateur, conventions(:analyse_de_marseille))
  end

  test 'accès autorisé pour un administrateur sur une convention de son organisation' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.services_for_adherent?
    assert @policy.show?
    assert @policy.destroy?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.pdf?
    assert @policy.analyser?
    assert @policy.analyses?
  end

  test 'accès autorisé pour un administrateur sur une analyse déposée dans son organisation' do
    assert @policy_analyse.show?
    assert @policy_analyse.edit?
    assert @policy_analyse.update?
    assert @policy_analyse.destroy?
    assert @policy_analyse.relancer?
    assert @policy_analyse.valider?
  end

  test 'accès interdit pour un administrateur sur une analyse déposée dans son organisation' do
    refute @policy_analyse.pdf?
  end

  test "accès interdit pour un administrateur sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end

  test 'accès interdit pour un administrateur sur une analyse déposée dans une autre organisation' do
    refute @policy_analyse_autre_org.show?
    refute @policy_analyse_autre_org.edit?
    refute @policy_analyse_autre_org.update?
    refute @policy_analyse_autre_org.destroy?
    refute @policy_analyse_autre_org.relancer?
    refute @policy_analyse_autre_org.valider?
  end

  test 'scope : un administrateur ne voit que les conventions de son organisation' do
    scope = ConventionPolicy::Scope.new(@administrateur, Convention.all).resolve

    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
