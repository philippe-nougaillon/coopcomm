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

  # destroy
  test "accès autorisé pour un agent sur la page destroy d'un mouvement si c'est lui qui l'a créé" do
    assert @policy.destroy?
  end

  test "accès interdit pour un agent sur la page destroy d'un mouvement si ce n'est pas lui qui l'a créé" do
    policy = MouvementPolicy.new(users(:martin_technique_paris), @mouvement)

    refute policy.destroy?
  end

  # reserve
  test "accès autorisé pour un administrateur sur la page reserve d'un mouvement" do
    assert @policy.reserve?
  end
end
