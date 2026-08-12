# frozen_string_literal: true

require 'test_helper'

class ManagerCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo)

    cotation_créée = cotations(:cotation_paris)
    cotation_envoyée = cotations(:cotation_envoyée)
    cotation_validée = cotations(:cotation_validée)
    cotation_autre_service = cotations(:cotation_secretariat)
    cotation_autre_org = cotations(:cotation_marseille)

    @policy = CotationPolicy.new(@manager, cotation_créée)
    @policy_envoyée = CotationPolicy.new(@manager, cotation_envoyée)
    @policy_validée = CotationPolicy.new(@manager, cotation_validée)
    @policy_autre_service = CotationPolicy.new(@manager, cotation_autre_service)
    @policy_autre_org = CotationPolicy.new(@manager, cotation_autre_org)
  end

  test 'accès autorisé pour un manager sur une cotation créée de son service' do
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

  test 'accès interdit pour un manager sur une cotation créée de son service' do
    refute @policy.create_commande?
    refute @policy.signer?
    refute @policy.signer_do?
  end

  test 'accès autorisé pour un manager sur une cotation envoyée de son service' do
    assert @policy_envoyée.show?
    assert @policy_envoyée.pdf?
    assert @policy_envoyée.destroy?
    assert @policy_envoyée.envoyer?
    assert @policy_envoyée.valider?
    assert @policy_envoyée.refuser?
  end

  test 'accès interdit pour un manager sur une cotation envoyée de son service' do
    refute @policy_envoyée.update?
    refute @policy_envoyée.create_commande?
  end

  test 'accès autorisé pour un manager sur une cotation validée de son service' do
    assert @policy_validée.show?
    assert @policy_validée.destroy?
    assert @policy_validée.create_commande?
  end

  test 'accès interdit pour un manager sur une cotation validée de son service' do
    refute @policy_validée.update?
  end

  test "accès interdit pour un manager sur une cotation d'un service qu'il ne gère pas" do
    refute @policy_autre_service.create?
    refute @policy_autre_service.show?
    refute @policy_autre_service.pdf?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.envoyer?
    refute @policy_autre_service.valider?
    refute @policy_autre_service.refuser?
    refute @policy_autre_service.create_commande?
    refute @policy_autre_service.signer?
  end

  test "accès interdit pour un manager sur une cotation d'une autre organisation" do
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

  test "scope : un manager ne voit que les cotations des services qu'il gère" do
    scope = CotationPolicy::Scope.new(@manager, Cotation.all).resolve

    assert_includes scope, cotations(:cotation_paris)
    refute_includes scope, cotations(:cotation_secretariat)
    refute_includes scope, cotations(:cotation_marseille)
  end
end
