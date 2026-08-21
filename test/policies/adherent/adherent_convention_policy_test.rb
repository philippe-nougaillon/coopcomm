# frozen_string_literal: true

require 'test_helper'

class AdherentConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)

    convention = conventions(:convention_paris)
    convention_autre_adherent = conventions(:convention_marseille)

    @policy = ConventionPolicy.new(@adherent, convention)
    @policy_autre_adherent = ConventionPolicy.new(@adherent, convention_autre_adherent)
  end

  test 'accès autorisé pour un adhérent sur une convention dont il est titulaire' do
    assert @policy.index?
    assert @policy.show?
  end

  test 'accès interdit pour un adhérent sur une convention dont il est titulaire' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.services_for_adherent?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test "accès interdit pour un adhérent sur une convention d'un autre titulaire" do
    refute @policy_autre_adherent.show?
    refute @policy_autre_adherent.destroy?
  end

  test 'scope : un adhérent ne voit que ses propres conventions' do
    scope = ConventionPolicy::Scope.new(@adherent, Convention.all).resolve

    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
