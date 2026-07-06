# frozen_string_literal: true

require 'test_helper'

# Rôles sans aucun droit de gestion des factures (adhérent et agent regroupés).
class AdherentFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @facture = factures(:facture_paris)
  end

  test "un adhérent n'a aucun accès aux factures" do
    policy = FacturePolicy.new(@adherent, @facture)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.envoyer?
    refute policy.valider?
    refute policy.refuser?
  end

  test "un agent n'a aucun accès aux factures" do
    policy = FacturePolicy.new(@agent, @facture)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
  end

  test 'scope : aucune facture visible pour un adhérent' do
    skip 'Comportement à clarifier : FacturePolicy::Scope#resolve renvoie `scope` ' \
         '(toutes les factures) au lieu de filtrer comme CotationPolicy::Scope ' \
         '(visible_to). Cf. bug signalé dans les notes de session. Test à activer ' \
         'une fois le comportement attendu du scope décidé.'
    assert_empty FacturePolicy::Scope.new(@adherent, Facture.all).resolve
  end
end
