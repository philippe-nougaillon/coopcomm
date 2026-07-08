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

  # Décision : le Scope des factures est un pass-through volontaire (il ne filtre
  # PAS). Le périmètre est appliqué dans FacturesController#index et l'accès des
  # adhérents est déjà verrouillé par index?/show? = false (tests ci-dessus).
  # On épingle ce comportement pour éviter qu'on le "corrige" par erreur.
  test 'scope : pass-through volontaire (ne filtre pas les factures)' do
    scope = FacturePolicy::Scope.new(@adherent, Facture.all).resolve

    assert_equal Facture.all.pluck(:id).sort, scope.pluck(:id).sort
  end
end
