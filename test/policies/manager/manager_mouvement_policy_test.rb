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

  # New
  test "accès autorisé pour un manager sur la page new d'un mouvement" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un manager sur la page create d'un mouvement" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un manager sur la page edit d'un mouvement" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un manager sur la page update d'un mouvement" do
    assert @policy.update?
  end
end
