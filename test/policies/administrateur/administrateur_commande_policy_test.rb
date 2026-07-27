# frozen_string_literal: true

require 'test_helper'

# Miroir de administrateur_facture_policy_test.rb (+ create_facture?).
class AdministrateurCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:administrateur_paris) # administrateur de mairie_paris

    @commande = commandes(:commande_paris)              # mairie_paris, état « créé »
    @commande_envoyée = commandes(:commande_secretariat) # mairie_paris, état « envoyé »
    @commande_validée = commandes(:commande_validée)     # mairie_paris, état « validé »
    @commande_autre_org = commandes(:commande_marseille) # mairie_marseille
  end

  test 'index autorisé pour un administrateur' do
    assert CommandePolicy.new(@admin, @commande).index?
  end

  test 'gère toutes les commandes de son organisation' do
    policy = CommandePolicy.new(@admin, @commande)
    assert policy.show?
    assert policy.destroy?
    assert policy.pdf?
    assert policy.envoyer?
    assert policy.valider?
    assert policy.refuser?
  end

  test 'update autorisé sur une commande modifiable (créé) de son organisation' do
    policy = CommandePolicy.new(@admin, @commande)
    assert policy.update?
    assert policy.edit?
  end

  test 'update interdit sur une commande envoyée même pour un administrateur' do
    policy = CommandePolicy.new(@admin, @commande_envoyée)
    refute policy.update?
    refute policy.edit?
  end

  # --- create_facture? (manage? && validé?) ---

  test 'create_facture autorisé sur une commande validée de son organisation' do
    assert CommandePolicy.new(@admin, @commande_validée).create_facture?
  end

  test 'create_facture interdit sur une commande non validée' do
    refute CommandePolicy.new(@admin, @commande).create_facture?          # créé
    refute CommandePolicy.new(@admin, @commande_envoyée).create_facture?  # envoyé
  end

  test "aucun accès aux commandes d'une autre organisation" do
    policy = CommandePolicy.new(@admin, @commande_autre_org)
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
  end
end
