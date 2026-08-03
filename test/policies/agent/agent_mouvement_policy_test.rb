# frozen_string_literal: true

require 'test_helper'

class AgentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)

    @mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(agent, @mouvement)
  end

  # Index
  test 'accès interdit pour un agent sur la page index des mouvements' do
    refute @policy.index?
  end

  # show
  test "accès interdit pour un agent sur la page show d'un mouvement" do
    refute @policy.show?
  end

  # New
  test "accès interdit pour un agent sur la page new d'un mouvement" do
    refute @policy.new?
  end

  # Create
  test "accès interdit pour un agent sur la page create d'un mouvement" do
    refute @policy.create?
  end

  # Edit
  test "accès interdit pour un agent sur la page edit d'un mouvement" do
    refute @policy.edit?
  end

  # Update
  test "accès interdit pour un agent sur la page update d'un mouvement" do
    refute @policy.update?
  end

  # reserve
  test "accès autorisé pour un administrateur sur la page reserve d'un mouvement" do
    assert @policy.reserve?
  end

  # libere
  test "un agent peut libérer sa propre réservation" do
    assert @policy.libere?
  end

  test "un agent ne peut pas libérer la réservation d'un autre" do
    policy = MouvementPolicy.new(users(:martin_technique_paris), @mouvement)

    refute policy.libere?
  end
end
