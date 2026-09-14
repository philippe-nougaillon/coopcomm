# frozen_string_literal: true

require 'test_helper'

class AgentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)

    mouvement = mouvements(:mouvement_tondeuse)
    mouvement_autre_org = mouvements(:mouvement_marseille)

    @policy = MouvementPolicy.new(agent, mouvement)
    @policy_autre_agent = MouvementPolicy.new(users(:martin_technique_paris), mouvement)
    @policy_autre_org = MouvementPolicy.new(agent, mouvement_autre_org)
  end

  test 'accès autorisé pour un agent sur sa propre réservation' do
    assert @policy.reserve?
    assert @policy.libere?
  end

  test 'accès interdit pour un agent sur sa propre réservation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
  end

  test "accès interdit pour un agent sur la réservation d'un autre agent" do
    refute @policy_autre_agent.libere?
  end

  test "accès interdit pour un agent sur une réservation d'une autre organisation" do
    refute @policy_autre_org.libere?
  end
end
