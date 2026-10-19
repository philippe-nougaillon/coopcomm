# frozen_string_literal: true

require 'test_helper'

class AdherentCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)

    commande_envoyée = commandes(:commande_secretariat)
    commande_créée = commandes(:commande_paris)
    commande_autre_adherent = commandes(:commande_marseille)

    @policy = CommandePolicy.new(@adherent, commande_envoyée)
    @policy_créée = CommandePolicy.new(@adherent, commande_créée)
    @policy_autre_adherent = CommandePolicy.new(@adherent, commande_autre_adherent)
  end

  test 'accès autorisé pour un adhérent sur une commande envoyée dont il est le destinataire' do
    assert @policy.show?
    assert @policy.pdf?
  end

  test 'accès interdit pour un adhérent sur une commande envoyée dont il est le destinataire' do
    refute @policy.index?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.refuser?
    refute @policy.create_facture?
  end

  test 'accès interdit pour un adhérent sur une commande créée dont il est le destinataire' do
    refute @policy_créée.show?
    refute @policy_créée.pdf?
  end

  test "accès interdit pour un adhérent sur une commande d'un autre adhérent" do
    refute @policy_autre_adherent.show?
    refute @policy_autre_adherent.pdf?
  end

  test 'scope : un adhérent ne voit que ses propres commandes déjà envoyées' do
    scope = CommandePolicy::Scope.new(@adherent, Commande.all).resolve

    assert_includes scope, commandes(:commande_secretariat)
    refute_includes scope, commandes(:commande_paris)
    refute_includes scope, commandes(:commande_marseille)
  end
end
