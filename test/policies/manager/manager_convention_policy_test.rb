# frozen_string_literal: true

require 'test_helper'

class ManagerConventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo)

    convention = conventions(:convention_paris)
    convention_autre_org = conventions(:convention_marseille)

    @policy = ConventionPolicy.new(@manager, convention)
    @policy_analyse = ConventionPolicy.new(@manager, conventions(:analyse_de_weil))
    @policy_analyse_hors_de_ses_services = ConventionPolicy.new(@manager, conventions(:analyse_hors_des_services_de_hidalgo))
    @policy_autre_service = ConventionPolicy.new(users(:manager_paris), convention)
    @policy_analyse_d_un_autre = ConventionPolicy.new(users(:manager_paris), conventions(:analyse_de_patrick))
    @policy_autre_org = ConventionPolicy.new(@manager, convention_autre_org)
  end

  test 'accès autorisé pour un manager sur une convention de son service' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.create?
    assert @policy.services_for_adherent?
    assert @policy.show?
    assert @policy.destroy?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.pdf?
    assert @policy.analyser?
    assert @policy.analyses?
  end

  test 'accès autorisé pour un manager sur une analyse qu’il a déposée' do
    assert @policy_analyse.show?
    assert @policy_analyse.edit?
    assert @policy_analyse.update?
    assert @policy_analyse.destroy?
    assert @policy_analyse.relancer?
    assert @policy_analyse.valider?
  end

  test 'accès interdit pour un manager sur une analyse qu’il a déposée' do
    refute @policy_analyse.pdf?
  end

  test 'accès autorisé pour un manager sur une analyse qu’il a déposée sur un service qu’il ne gère pas' do
    assert @policy_analyse_hors_de_ses_services.show?
    assert @policy_analyse_hors_de_ses_services.edit?
    assert @policy_analyse_hors_de_ses_services.update?
    assert @policy_analyse_hors_de_ses_services.destroy?
    assert @policy_analyse_hors_de_ses_services.relancer?
  end

  test 'accès interdit pour un manager sur une analyse qu’il a déposée sur un service qu’il ne gère pas' do
    refute @policy_analyse_hors_de_ses_services.valider?
  end

  test "accès interdit pour un manager sur une convention d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.edit?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
  end

  test 'accès interdit pour un manager sur une analyse déposée par un autre sur un service qu’il gère' do
    refute @policy_analyse_d_un_autre.show?
    refute @policy_analyse_d_un_autre.edit?
    refute @policy_analyse_d_un_autre.update?
    refute @policy_analyse_d_un_autre.destroy?
    refute @policy_analyse_d_un_autre.relancer?
    refute @policy_analyse_d_un_autre.valider?
  end

  test "accès interdit pour un manager sur une convention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end

  test "scope : un manager ne voit que les conventions des services qu'il gère" do
    scope = ConventionPolicy::Scope.new(@manager, Convention.all).resolve

    assert_includes scope, conventions(:convention_paris)
    refute_includes scope, conventions(:convention_marseille)
  end
end
