# frozen_string_literal: true

require 'test_helper'

class AdministrateurMouvementPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    mouvement = mouvements(:mouvement_tondeuse)
    mouvement_autre_org = mouvements(:mouvement_marseille)

    @policy = MouvementPolicy.new(administrateur, mouvement)
    @policy_autre_org = MouvementPolicy.new(administrateur, mouvement_autre_org)
  end

  test 'accès autorisé pour un administrateur sur un mouvement de son organisation' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.reserve?
    assert @policy.libere?
  end

  test 'accès interdit pour un administrateur sur un mouvement de son organisation' do
    refute @policy.show?
  end

  test "accès interdit pour un administrateur sur un mouvement d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.libere?
  end
end
