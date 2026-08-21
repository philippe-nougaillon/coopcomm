# frozen_string_literal: true

require 'test_helper'

class AdherentMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    mouvement = mouvements(:mouvement_tondeuse)
    mouvement_sien = mouvements(:mouvement_adherent)

    @policy = MouvementPolicy.new(adherent, mouvement)
    @policy_sien = MouvementPolicy.new(adherent, mouvement_sien)
  end

  test "accès interdit pour un adhérent sur la réservation d'un agent" do
    refute @policy.index?
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.reserve?
    refute @policy.libere?
  end

  test 'accès autorisé pour un adhérent sur une réservation dont il est propriétaire' do
    assert @policy_sien.libere?
  end
end
