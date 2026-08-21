# frozen_string_literal: true

require 'test_helper'

class AdministrateurFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris)

    facture_créée = factures(:facture_paris)
    facture_envoyée = factures(:facture_secretariat)
    facture_autre_org = factures(:facture_marseille)

    @policy = FacturePolicy.new(@administrateur, facture_créée)
    @policy_envoyée = FacturePolicy.new(@administrateur, facture_envoyée)
    @policy_autre_org = FacturePolicy.new(@administrateur, facture_autre_org)
  end

  test 'accès autorisé pour un administrateur sur une facture créée de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.pdf?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  test 'accès autorisé pour un administrateur sur une facture envoyée de son organisation' do
    assert @policy_envoyée.show?
    assert @policy_envoyée.pdf?
    assert @policy_envoyée.destroy?
    assert @policy_envoyée.envoyer?
    assert @policy_envoyée.valider?
    assert @policy_envoyée.refuser?
  end

  test 'accès interdit pour un administrateur sur une facture envoyée de son organisation' do
    refute @policy_envoyée.update?
  end

  test "accès interdit pour un administrateur sur une facture d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.pdf?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.envoyer?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
  end

  test 'scope : un administrateur ne voit que les factures de son organisation' do
    scope = FacturePolicy::Scope.new(@administrateur, Facture.all).resolve

    assert_includes scope, factures(:facture_paris)
    refute_includes scope, factures(:facture_marseille)
  end
end
