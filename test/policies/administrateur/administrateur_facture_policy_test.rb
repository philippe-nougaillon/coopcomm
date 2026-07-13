# frozen_string_literal: true

require 'test_helper'

class AdministrateurFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:administrateur_paris) # administrateur de mairie_paris

    @facture = factures(:facture_paris)              # mairie_paris, état « créé »
    @facture_envoyée = factures(:facture_secretariat) # mairie_paris, état « envoyé »
    @facture_autre_org = factures(:facture_marseille) # mairie_marseille
  end

  test 'index autorisé pour un administrateur' do
    assert FacturePolicy.new(@admin, @facture).index?
  end

  test 'gère toutes les factures de son organisation' do
    policy = FacturePolicy.new(@admin, @facture)
    assert policy.show?
    assert policy.destroy?
    assert policy.pdf?
    assert policy.envoyer?
    assert policy.valider?
    assert policy.refuser?
  end

  test 'update autorisé sur une facture modifiable (créé) de son organisation' do
    policy = FacturePolicy.new(@admin, @facture)
    assert policy.update?
    assert policy.edit?
  end

  test 'update interdit sur une facture envoyée même pour un administrateur' do
    policy = FacturePolicy.new(@admin, @facture_envoyée)
    refute policy.update?
    refute policy.edit?
  end

  test "aucun accès aux factures d'une autre organisation" do
    policy = FacturePolicy.new(@admin, @facture_autre_org)
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
  end
end
