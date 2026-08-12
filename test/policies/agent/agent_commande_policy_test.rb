# frozen_string_literal: true

require 'test_helper'

class AgentCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @agent = users(:martin_technique_paris)

    commande = commandes(:commande_paris)

    @policy = CommandePolicy.new(@agent, commande)
  end

  test 'accès interdit pour un agent sur une commande de son organisation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.pdf?
    refute @policy.update?
    refute @policy.destroy?
    refute @policy.envoyer?
    refute @policy.valider?
    refute @policy.refuser?
    refute @policy.create_facture?
  end

  test 'scope : un agent ne voit aucune commande' do
    assert_empty CommandePolicy::Scope.new(@agent, Commande.all).resolve
  end
end
