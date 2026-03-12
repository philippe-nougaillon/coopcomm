require "test_helper"

class AgentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)
    
    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(agent, mouvement)
  end

  # Index
  test "accès interdit pour un agent sur la page index des mouvements" do
    refute @policy.index?
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
end
