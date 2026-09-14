# frozen_string_literal: true

require 'test_helper'

class ManagerCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo)

    commande_créée = commandes(:commande_paris)
    commande_envoyée = commandes(:commande_envoyée)
    commande_validée = commandes(:commande_validée)
    commande_autre_service = commandes(:commande_secretariat)
    commande_autre_org = commandes(:commande_marseille)

    @policy = CommandePolicy.new(@manager, commande_créée)
    @policy_envoyée = CommandePolicy.new(@manager, commande_envoyée)
    @policy_validée = CommandePolicy.new(@manager, commande_validée)
    @policy_autre_service = CommandePolicy.new(@manager, commande_autre_service)
    @policy_autre_org = CommandePolicy.new(@manager, commande_autre_org)
  end

  test 'accès autorisé pour un manager sur une commande créée de son service' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.pdf?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  test 'accès interdit pour un manager sur une commande créée de son service' do
    refute @policy.create_facture?
  end

  test 'accès autorisé pour un manager sur une commande envoyée de son service' do
    assert @policy_envoyée.show?
    assert @policy_envoyée.pdf?
    assert @policy_envoyée.destroy?
    assert @policy_envoyée.envoyer?
    assert @policy_envoyée.valider?
    assert @policy_envoyée.refuser?
  end

  test 'accès interdit pour un manager sur une commande envoyée de son service' do
    refute @policy_envoyée.update?
    refute @policy_envoyée.create_facture?
  end

  test 'accès autorisé pour un manager sur une commande validée de son service' do
    assert @policy_validée.show?
    assert @policy_validée.destroy?
    assert @policy_validée.create_facture?
  end

  test 'accès interdit pour un manager sur une commande validée de son service' do
    refute @policy_validée.update?
  end

  test "accès interdit pour un manager sur une commande d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.pdf?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.envoyer?
    refute @policy_autre_service.valider?
    refute @policy_autre_service.refuser?
    refute @policy_autre_service.create_facture?
  end

  test "accès interdit pour un manager sur une commande d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.pdf?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.envoyer?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
    refute @policy_autre_org.create_facture?
  end

  test "scope : un manager ne voit que les commandes des services qu'il gère" do
    scope = CommandePolicy::Scope.new(@manager, Commande.all).resolve

    assert_includes scope, commandes(:commande_paris)
    refute_includes scope, commandes(:commande_secretariat)
    refute_includes scope, commandes(:commande_marseille)
  end
end
