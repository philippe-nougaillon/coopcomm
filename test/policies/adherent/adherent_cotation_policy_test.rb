# frozen_string_literal: true

require 'test_helper'

# Droits d'un adhérent sur les cotations : il consulte les SIENNES (index, show,
# pdf) et peut signer une cotation qui lui a été envoyée ; aucun droit de gestion.
# Un agent, lui, n'a aucun accès.
class AdherentCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @sienne = cotations(:cotation_paris)               # adhérent: weil, état créé
    @sienne_envoyee = cotations(:cotation_secretariat) # adhérent: weil, état envoyé
    @autre = cotations(:cotation_marseille)            # adhérent: michael_jackson
  end

  test 'un adhérent consulte ses propres cotations mais ne les gère pas' do
    policy = CotationPolicy.new(@adherent, @sienne)
    assert policy.index?
    assert policy.show?
    assert policy.pdf?
    refute policy.new?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
    refute policy.envoyer?
    refute policy.valider?
    refute policy.refuser?
  end

  test "un adhérent ne voit pas la cotation d'un autre adhérent" do
    policy = CotationPolicy.new(@adherent, @autre)
    refute policy.show?
    refute policy.pdf?
  end

  test 'un adhérent peut signer une cotation qui lui a été envoyée' do
    policy = CotationPolicy.new(@adherent, @sienne_envoyee)
    assert policy.signer?
    assert policy.signer_do?
  end

  test "un adhérent ne peut pas signer une cotation non encore envoyée (créé)" do
    policy = CotationPolicy.new(@adherent, @sienne)
    refute policy.signer?
    refute policy.signer_do?
  end

  test "un adhérent ne peut pas signer la cotation d'un autre adhérent, même envoyée" do
    @autre.update!(workflow_state: 'envoyé') # envoyée (can_signer?) mais pas la sienne
    policy = CotationPolicy.new(@adherent, @autre)
    refute policy.signer?
    refute policy.signer_do?
  end

  test 'scope : un adhérent ne voit que ses propres cotations' do
    resolved = CotationPolicy::Scope.new(@adherent, Cotation.all).resolve
    assert_includes resolved, @sienne
    assert_includes resolved, @sienne_envoyee
    refute_includes resolved, @autre
  end

  test "un agent n'a aucun accès aux cotations" do
    policy = CotationPolicy.new(@agent, @sienne)
    refute policy.index?
    refute policy.new?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.signer?
  end

  test 'scope : aucune cotation visible pour un agent' do
    assert_empty CotationPolicy::Scope.new(@agent, Cotation.all).resolve
  end
end
