# frozen_string_literal: true

require 'test_helper'

class ManagerUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    user = users(:agent_whatsapp)
    user_hors_de_ses_services = users(:john_wick)
    user_autre_org = users(:agent_marseille)

    @policy = UserPolicy.new(manager, user)
    @policy_autre_service = UserPolicy.new(manager, user_hors_de_ses_services)
    @policy_autre_org = UserPolicy.new(manager, user_autre_org)
    @policy_manager = UserPolicy.new(manager, users(:manager_paris))
    @policy_administrateur = UserPolicy.new(manager, users(:administrateur_paris))
    @policy_user_myself = UserPolicy.new(manager, manager)
  end

  test 'accès autorisé pour un manager sur un user de son service' do
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

  test 'accès interdit pour un manager sur un user de son service' do
    refute @policy.edit_password?
    refute @policy.update_password?
  end

  test "accès interdit pour un manager sur un user d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.edit?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.inviter?
    refute @policy_autre_service.reactivate?
  end

  test "accès interdit pour un manager sur un user d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.inviter?
    refute @policy_autre_org.reactivate?
  end

  test 'accès autorisé pour un manager sur un autre manager de son service' do
    assert @policy_manager.show?
    assert @policy_manager.inviter?
    assert @policy_manager.reactivate?
  end

  test 'accès interdit pour un manager sur un autre manager de son service' do
    refute @policy_manager.edit?
    refute @policy_manager.update?
    refute @policy_manager.destroy?
  end

  test 'accès autorisé pour un manager sur un administrateur de son service' do
    assert @policy_administrateur.show?
    assert @policy_administrateur.inviter?
    assert @policy_administrateur.reactivate?
  end

  test 'accès interdit pour un manager sur un administrateur de son service' do
    refute @policy_administrateur.edit?
    refute @policy_administrateur.update?
    refute @policy_administrateur.destroy?
  end

  test 'accès autorisé pour un manager sur sa propre fiche' do
    assert @policy_user_myself.show?
    assert @policy_user_myself.edit?
    assert @policy_user_myself.update?
    assert @policy_user_myself.edit_password?
    assert @policy_user_myself.update_password?
    assert @policy_user_myself.reactivate?
  end

  test 'accès interdit pour un manager sur sa propre fiche' do
    refute @policy_user_myself.destroy?
    refute @policy_user_myself.inviter?
  end
end
