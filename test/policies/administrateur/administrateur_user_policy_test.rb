# frozen_string_literal: true

require 'test_helper'

class AdministrateurUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    user = users(:bond)
    user_hors_de_ses_services = users(:john_wick)
    user_autre_org = users(:agent_marseille)

    @policy = UserPolicy.new(administrateur, user)
    @policy_autre_service = UserPolicy.new(administrateur, user_hors_de_ses_services)
    @policy_autre_org = UserPolicy.new(administrateur, user_autre_org)
    @policy_user_myself = UserPolicy.new(administrateur, administrateur)
    @policy_dernier_administrateur = UserPolicy.new(users(:administrateur_seul), users(:administrateur_seul))
  end

  test 'accès autorisé pour un administrateur sur un user de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.inviter?
    assert @policy.reactivate?
    assert @policy.agent_calendrier?
    assert @policy.import?
    assert @policy.import_do?
  end

  test 'accès interdit pour un administrateur sur un user de son organisation' do
    refute @policy.edit_password?
    refute @policy.update_password?
    refute @policy.desactiver_compte?
  end

  test 'affichage interdit pour un administrateur sur un user de son organisation' do
    refute @policy.voir_desactiver_compte?
  end

  test 'accès autorisé pour un administrateur sur un user de son organisation hors de ses services' do
    assert @policy_autre_service.show?
    assert @policy_autre_service.edit?
    assert @policy_autre_service.update?
    assert @policy_autre_service.destroy?
    assert @policy_autre_service.inviter?
    assert @policy_autre_service.reactivate?
  end

  test "accès interdit pour un administrateur sur un user d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.inviter?
    refute @policy_autre_org.reactivate?
  end

  test 'accès autorisé pour un administrateur sur sa propre fiche' do
    assert @policy_user_myself.show?
    assert @policy_user_myself.edit?
    assert @policy_user_myself.update?
    assert @policy_user_myself.edit_password?
    assert @policy_user_myself.update_password?
    assert @policy_user_myself.reactivate?
    assert @policy_user_myself.desactiver_compte?
  end

  test 'accès interdit pour un administrateur sur sa propre fiche' do
    refute @policy_user_myself.destroy?
    refute @policy_user_myself.inviter?
  end

  test 'affichage autorisé pour un administrateur sur sa propre fiche' do
    assert @policy_user_myself.voir_desactiver_compte?
  end

  test 'accès interdit pour un administrateur, dernier de son organisation, sur sa propre fiche' do
    refute @policy_dernier_administrateur.desactiver_compte?
  end

  test 'affichage autorisé pour un administrateur, dernier de son organisation, sur sa propre fiche' do
    assert @policy_dernier_administrateur.voir_desactiver_compte?
  end
end
