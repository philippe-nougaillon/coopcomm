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

  test "un adhérent a accès à l'index des conventions" do
    policy = ConventionPolicy.new(@adherent, @convention)
    assert policy.index?
  end

  test "un adhérent n'a pas d'accès aux actions de gestion des conventions" do
    policy = ConventionPolicy.new(@adherent, @convention)
    refute policy.new?
    refute policy.services_for_adherent?
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

  test "scope : conventions visibles pour un adhérent" do
    scoped_conventions = AdherentConventionPolicy::Scope.new(@adherent, Convention).resolve
    assert_equal [@adherent_convention], scoped_conventions.to_a
  end

  test 'scope : aucune convention visible pour un agent' do
    assert_empty ConventionPolicy::Scope.new(@agent, Convention.all).resolve
  end
end
