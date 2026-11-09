# frozen_string_literal: true

require 'test_helper'

class AdherentCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)

    cotation_envoyée = cotations(:cotation_secretariat)
    cotation_créée = cotations(:cotation_paris)
    cotation_autre_adherent = cotations(:cotation_envoyée)

    @policy = CotationPolicy.new(@adherent, cotation_envoyée)
    @policy_créée = CotationPolicy.new(@adherent, cotation_créée)
    @policy_autre_adherent = CotationPolicy.new(@adherent, cotation_autre_adherent)
  end

  test 'accès autorisé pour un adhérent sur une cotation envoyée dont il est le destinataire' do
    assert @policy.show?
    assert @policy.pdf?
    assert @policy.signer?
    assert @policy.signer_do?
    assert @policy.refuser?
  end

  test 'accès interdit pour un adhérent sur une cotation envoyée dont il est le destinataire' do
    refute @policy.index?
    refute @policy.new?
    refute @policy.create?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.create_commande?
  end

  test 'accès interdit pour un adhérent sur une cotation créée dont il est le destinataire' do
    refute @policy_créée.show?
    refute @policy_créée.pdf?
    refute @policy_créée.signer?
    refute @policy_créée.signer_do?
    refute @policy_créée.refuser?
  end

  test "accès interdit pour un adhérent sur une cotation d'un autre adhérent" do
    refute @policy_autre_adherent.show?
    refute @policy_autre_adherent.pdf?
    refute @policy_autre_adherent.signer?
    refute @policy_autre_adherent.signer_do?
    refute @policy_autre_adherent.refuser?
  end

  test 'scope : un adhérent ne voit que ses propres cotations déjà envoyées' do
    scope = CotationPolicy::Scope.new(@adherent, Cotation.all).resolve

    assert_includes scope, cotations(:cotation_secretariat)
    refute_includes scope, cotations(:cotation_paris)
    refute_includes scope, cotations(:cotation_envoyée)
  end
end
