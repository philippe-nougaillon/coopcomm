# frozen_string_literal: true

require 'test_helper'

class AdministrateurCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris) # mairie_paris

    cotation = cotations(:cotation_paris) # mairie_paris
    cotation_autre_org = cotations(:cotation_marseille) # mairie_marseille

    @policy = CotationPolicy.new(@administrateur, cotation)
    @policy_autre_org = CotationPolicy.new(@administrateur, cotation_autre_org)
  end

  test 'index autorisé pour un administrateur' do
    assert @policy.index?
  end

  test 'show / update / destroy / pdf / create autorisés dans son organisation' do
    assert @policy.show?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.pdf?
    assert @policy.create?
  end

  test 'update interdit sur une cotation envoyée, même pour un administrateur' do
    # cotation_secretariat (mairie_paris) est à l'état « envoyé »
    policy = CotationPolicy.new(@administrateur, cotations(:cotation_secretariat))
    refute policy.update?
    refute policy.edit?
  end

  test "accès interdit sur une cotation d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.create?
  end

  test "scope : un administrateur voit les cotations de son organisation, pas celles d'une autre" do
    scope = CotationPolicy::Scope.new(@administrateur, Cotation.all).resolve
    assert_includes scope, cotations(:cotation_paris)
    refute_includes scope, cotations(:cotation_marseille)
  end
end
