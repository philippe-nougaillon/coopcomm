# frozen_string_literal: true

require 'test_helper'

# Rôles sans aucun droit de gestion des commandes (adhérent et agent regroupés).
# Miroir de adherent_facture_policy_test.rb.
class AdherentCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @commande = commandes(:commande_paris)
  end

  test "un adhérent n'a aucun accès aux commandes" do
    policy = CommandePolicy.new(@adherent, @commande)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.envoyer?
    refute policy.valider?
    refute policy.refuser?
    refute policy.create_facture?
  end

  test "un agent n'a aucun accès aux commandes" do
    policy = CommandePolicy.new(@agent, @commande)
    refute policy.index?
    refute policy.show?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.create_facture?
  end

  # Décision : le Scope des commandes est un pass-through volontaire (il ne filtre
  # PAS). Le périmètre est appliqué dans CommandesController#index et l'accès des
  # adhérents est déjà verrouillé par index?/show? = false (tests ci-dessus).
  # On épingle ce comportement pour éviter qu'on le "corrige" par erreur.
  test 'scope : pass-through volontaire (ne filtre pas les commandes)' do
    scope = CommandePolicy::Scope.new(@adherent, Commande.all).resolve

    assert_equal Commande.all.pluck(:id).sort, scope.pluck(:id).sort
  end
end
