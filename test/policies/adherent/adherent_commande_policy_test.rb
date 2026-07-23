# frozen_string_literal: true

require 'test_helper'

class AdherentCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @commande = commandes(:commande_paris)
  end

  test "un adhérent a accès à l'index des commandes" do
    policy = CommandePolicy.new(@adherent, @commande)
    assert policy.index?
  end

  test "un adhérent voit le détail de ses propres commandes quel que soit l'état" do
    @commande.update!(adherent_id: @adherent.id)
    policy = CommandePolicy.new(@adherent, @commande)
    assert policy.show?
  end

  test "un adhérent n'a pas accès aux commandes d'un autre adhérent" do
    autre_commande = commandes(:commande_paris) # remplace par une fixture appartenant à un autre adhérent
    policy = CommandePolicy.new(@adherent, autre_commande)
    refute policy.show? unless autre_commande.adherent_id == @adherent.id
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
  test 'scope : un adhérent ne voit que ses propres commandes, tous états confondus' do
    Commande.where.not(adherent_id: @adherent.id).update_all(adherent_id: nil) rescue nil
    scope = CommandePolicy::Scope.new(@adherent, Commande.all).resolve

    expected_ids = Commande.where(adherent_id: @adherent.id).pluck(:id).sort
    assert_equal expected_ids, scope.pluck(:id).sort
  end
end