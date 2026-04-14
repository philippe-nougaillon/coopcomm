require "test_helper"

class ManagerMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)
    
    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(manager, mouvement)
  end

  # Index
  test "accès autorisé pour un manager sur la page index des mouvements" do
    assert @policy.index?
  end

  # show
  test "accès impossible pour un administrateur sur la page show d'un mouvement" do
    refute @policy.show?
  end

  # New
  test "accès autorisé pour un manager sur la page new d'un mouvement" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un manager sur la page create d'un mouvement" do
    assert @policy.create?
  end

  # Edit
  test "accès impossible pour un manager sur la page edit d'un mouvement" do
    refute @policy.edit?
  end

  # Update
  test "accès impossible pour un manager sur la page update d'un mouvement" do
    refute @policy.update?
  end

  # destroy
  test "accès autorisé pour un manager sur la page destroy d'un mouvement" do
    assert @policy.destroy?
  end

  # reserve
  test "accès autorisé pour un administrateur sur la page reserve d'un mouvement" do
    assert @policy.reserve?
  end
end
