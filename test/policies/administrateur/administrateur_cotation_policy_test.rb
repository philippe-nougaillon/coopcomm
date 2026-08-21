# frozen_string_literal: true

require 'test_helper'

class AdministrateurCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris)

    cotation_créée = cotations(:cotation_paris)
    cotation_envoyée = cotations(:cotation_secretariat)
    cotation_autre_org = cotations(:cotation_marseille)

    @policy = CotationPolicy.new(@administrateur, cotation_créée)
    @policy_envoyée = CotationPolicy.new(@administrateur, cotation_envoyée)
    @policy_autre_org = CotationPolicy.new(@administrateur, cotation_autre_org)
  end

  test 'accès autorisé pour un administrateur sur une cotation créée de son organisation' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.show?
    assert @policy.pdf?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  test 'accès interdit pour un administrateur sur une cotation créée de son organisation' do
    refute @policy.create_commande?
    refute @policy.signer?
    refute @policy.signer_do?
  end

  test 'accès autorisé pour un administrateur sur une cotation envoyée de son organisation' do
    assert @policy_envoyée.show?
    assert @policy_envoyée.pdf?
    assert @policy_envoyée.destroy?
    assert @policy_envoyée.envoyer?
    assert @policy_envoyée.valider?
    assert @policy_envoyée.refuser?
  end

  test 'accès interdit pour un administrateur sur une cotation envoyée de son organisation' do
    refute @policy_envoyée.update?
    refute @policy_envoyée.create_commande?
  end

  test "accès interdit pour un administrateur sur une cotation d'une autre organisation" do
    refute @policy_autre_org.create?
    refute @policy_autre_org.show?
    refute @policy_autre_org.pdf?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.envoyer?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
    refute @policy_autre_org.create_commande?
    refute @policy_autre_org.signer?
  end

  test 'scope : un administrateur ne voit que les cotations de son organisation' do
    scope = CotationPolicy::Scope.new(@administrateur, Cotation.all).resolve

    assert_includes scope, cotations(:cotation_paris)
    refute_includes scope, cotations(:cotation_marseille)
  end
end
