# frozen_string_literal: true

require 'test_helper'

class AdministrateurCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris)

    commande_créée = commandes(:commande_paris)
    commande_envoyée = commandes(:commande_secretariat)
    commande_validée = commandes(:commande_validée)
    commande_autre_org = commandes(:commande_marseille)

    @policy = CommandePolicy.new(@administrateur, commande_créée)
    @policy_envoyée = CommandePolicy.new(@administrateur, commande_envoyée)
    @policy_validée = CommandePolicy.new(@administrateur, commande_validée)
    @policy_autre_org = CommandePolicy.new(@administrateur, commande_autre_org)
  end

  test 'accès autorisé pour un administrateur sur une commande créée de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.pdf?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  test 'accès interdit pour un administrateur sur une commande créée de son organisation' do
    refute @policy.create_facture?
  end

  test 'accès autorisé pour un administrateur sur une commande envoyée de son organisation' do
    assert @policy_envoyée.show?
    assert @policy_envoyée.pdf?
    assert @policy_envoyée.destroy?
    assert @policy_envoyée.envoyer?
    assert @policy_envoyée.valider?
    assert @policy_envoyée.refuser?
  end

  test 'accès interdit pour un administrateur sur une commande envoyée de son organisation' do
    refute @policy_envoyée.update?
    refute @policy_envoyée.create_facture?
  end

  test 'accès autorisé pour un administrateur sur une commande validée de son organisation' do
    assert @policy_validée.show?
    assert @policy_validée.destroy?
    assert @policy_validée.create_facture?
  end

  test 'accès interdit pour un administrateur sur une commande validée de son organisation' do
    refute @policy_validée.update?
  end

  test "accès interdit pour un administrateur sur une commande d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.pdf?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.envoyer?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
    refute @policy_autre_org.create_facture?
  end

  test 'scope : un administrateur ne voit que les commandes de son organisation' do
    scope = CommandePolicy::Scope.new(@administrateur, Commande.all).resolve

    assert_includes scope, commandes(:commande_paris)
    refute_includes scope, commandes(:commande_marseille)
  end
end
