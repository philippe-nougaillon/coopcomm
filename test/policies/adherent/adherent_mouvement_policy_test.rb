require "test_helper"

class AdherentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)
    
    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(adherent, mouvement)
  end

  # Index
  test "accès interdit pour un adherent sur la page index des mouvements" do
    refute @policy.index?
  end

  # show
  test "accès interdit pour un adherent sur la page show d'un mouvement" do
    refute @policy.show?
  end

  # New
  test "accès interdit pour un adherent sur la page new d'un mouvement" do
    refute @policy.new?
  end

  # Create
  test "accès interdit pour un adherent sur la page create d'un mouvement" do
    refute @policy.create?
  end

  # Edit
  test "accès interdit pour un adherent sur la page edit d'un mouvement" do
    refute @policy.edit?
  end

  # Update
  test "accès interdit pour un adherent sur la page update d'un mouvement" do
    refute @policy.update?
  end

  # destroy
  test "accès interdit pour un adherent sur la page destroy d'un mouvement" do
    refute @policy.destroy?
  end

  # reserve
  test "accès interdit pour un adherent sur la page reserve d'un mouvement" do
    refute @policy.reserve?
  end
end
