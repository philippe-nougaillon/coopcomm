# frozen_string_literal: true

require 'test_helper'

class AdherentFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)

    facture_envoyée = factures(:facture_secretariat)
    facture_créée = factures(:facture_paris)
    facture_autre_adherent = factures(:facture_marseille)

    @policy = FacturePolicy.new(@adherent, facture_envoyée)
    @policy_créée = FacturePolicy.new(@adherent, facture_créée)
    @policy_autre_adherent = FacturePolicy.new(@adherent, facture_autre_adherent)
  end

  test 'accès autorisé pour un adhérent sur une facture envoyée dont il est le destinataire' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.pdf?
  end

  test 'accès interdit pour un adhérent sur une facture envoyée dont il est le destinataire' do
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.refuser?
  end

  test 'accès interdit pour un adhérent sur une facture créée dont il est le destinataire' do
    refute @policy_créée.show?
    refute @policy_créée.pdf?
  end

  test "accès interdit pour un adhérent sur une facture d'un autre adhérent" do
    refute @policy_autre_adherent.show?
    refute @policy_autre_adherent.pdf?
  end

  test 'scope : un adhérent ne voit que ses propres factures déjà envoyées' do
    scope = FacturePolicy::Scope.new(@adherent, Facture.all).resolve

    assert_includes scope, factures(:facture_secretariat)
    refute_includes scope, factures(:facture_paris)
    refute_includes scope, factures(:facture_marseille)
  end
end
