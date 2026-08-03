# frozen_string_literal: true

require 'test_helper'

class AdherentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    mouvement = mouvements(:mouvement_tondeuse)

    @policy = MouvementPolicy.new(adherent, mouvement)
  end

  # Index
  test 'accès interdit pour un adherent sur la page index des mouvements' do
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


  # reserve
  test "accès interdit pour un adherent sur la page reserve d'un mouvement" do
    refute @policy.reserve?
  end

  # libere
  test "accès interdit pour un adherent sur la page libere d'un mouvement" do
    refute @policy.libere?
  end

  # ÉPINGLAGE : un adhérent ne peut pas réserver (reserve? l'exclut), donc il ne
  # possède une réservation que s'il l'a créée avant de passer adhérent. Il peut
  # alors libérer la sienne, et elle seule. À inverser si le métier le refuse.
  test "un adherent peut libérer une réservation dont il est propriétaire" do
    adherent = users(:weil)
    sienne = Mouvement.create!(tool: tools(:cisaille), user: adherent, état: :réservé, date: Date.today)

    assert MouvementPolicy.new(adherent, sienne).libere?
  end
end
