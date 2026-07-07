# frozen_string_literal: true

require 'test_helper'

# Rôles sans aucun droit sur les conventions (adhérent et agent regroupés :
# tous deux n'ont aucune action autorisée, le test reste lisible groupé).
class AdherentConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)            # adhérent, par ailleurs titulaire de convention_paris
    @agent = users(:agent_whatsapp)     # agent
    @convention = conventions(:convention_paris)
  end

  test "un adhérent n'a aucun accès aux conventions" do
    policy = ConventionPolicy.new(@adherent, @convention)
    refute policy.index?
    refute policy.new?
    refute policy.services_for_adherent?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
  end

  test "un agent n'a aucun accès aux conventions" do
    policy = ConventionPolicy.new(@agent, @convention)
    refute policy.index?
    refute policy.new?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
  end

  test 'scope : aucune convention visible pour un adhérent' do
    assert_empty ConventionPolicy::Scope.new(@adherent, Convention.all).resolve
  end

  test 'scope : aucune convention visible pour un agent' do
    assert_empty ConventionPolicy::Scope.new(@agent, Convention.all).resolve
  end
end
