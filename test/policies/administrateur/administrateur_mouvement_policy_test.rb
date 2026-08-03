# frozen_string_literal: true

require 'test_helper'

class AdministrateurMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(administrateur, mouvement)
  end

  # Index
  test 'accès autorisé pour un administrateur sur la page index des mouvements' do
    assert @policy.index?
  end

  # show
  test "accès impossible pour un administrateur sur la page show d'un mouvement" do
    refute @policy.show?
  end

  # New
  test "accès autorisé pour un administrateur sur la page new d'un mouvement" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un administrateur sur la page create d'un mouvement" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un administrateur sur la page edit d'un mouvement" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un administrateur sur la page update d'un mouvement" do
    assert @policy.update?
  end


  # reserve
  test "accès autorisé pour un administrateur sur la page reserve d'un mouvement" do
    assert @policy.reserve?
  end

  # libere
  test "un administrateur peut libérer la réservation de n'importe qui" do
    assert @policy.libere?
  end
end
