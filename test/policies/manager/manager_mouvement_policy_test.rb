# frozen_string_literal: true

require 'test_helper'

class ManagerMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(manager, mouvement)
  end

  # Index
  test 'accès autorisé pour un manager sur la page index des mouvements' do
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
  test "accès autorisé pour un manager sur la page edit d'un mouvement" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un manager sur la page update d'un mouvement" do
    assert @policy.update?
  end


  # reserve
  test "accès autorisé pour un administrateur sur la page reserve d'un mouvement" do
    assert @policy.reserve?
  end

  # libere
  test "un manager peut libérer la réservation de n'importe qui" do
    assert @policy.libere?
  end

  test "un manager ne peut pas libérer une réservation d'une autre organisation" do
    policy = MouvementPolicy.new(users(:manager_marseille), mouvements(:mouvement_tondeuse))

    refute policy.libere?
  end
end
