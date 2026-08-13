# frozen_string_literal: true

require 'test_helper'

class ManagerInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    intervention = interventions(:intervention_paris)
    intervention_pointage = interventions(:intervention_repete)
    intervention_autre_org = interventions(:nettoyage_port)

    @policy = InterventionPolicy.new(manager, intervention)
    @policy_pointage = InterventionPolicy.new(manager, intervention_pointage)
    @policy_autre_service = InterventionPolicy.new(users(:manager_paris), intervention)
    @policy_autre_org = InterventionPolicy.new(manager, intervention_autre_org)
  end

  test 'accès autorisé pour un manager sur une intervention de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.purge?
    assert @policy.purger_photos_demande?
    assert @policy.terminer?
    assert @policy.valider?
    assert @policy.refuser?
    assert @policy.archiver?
    assert @policy.get_unavailable_elements?
    assert @policy.can_see_qrcode_pointage_pdf?
    assert @policy.services_for_adherent?
    assert @policy.agents_for_service?
    assert @policy.new_intervention_modele_pointage?
    assert @policy.create_intervention_modele_pointage?
  end

  test 'accès interdit pour un manager sur une intervention de son organisation' do
    refute @policy.pointer?
    refute @policy.pointage_statut?
    refute @policy.update_location?
  end

  test 'affichage autorisé pour un manager sur une intervention de son organisation' do
    assert @policy.voir_assignation?
    assert @policy.voir_realisation?
    assert @policy.voir_activite?
    assert @policy.voir_dates_prevues?
  end

  test 'affichage interdit pour un manager sur une intervention de son organisation' do
    refute @policy.voir_pointages?
    refute @policy.voir_agent_des_pointages?
    refute @policy.voir_qrcode_pointage?
    refute @policy.voir_temps?
    refute @policy.voir_compte_rendu?
  end

  test 'saisie autorisée pour un manager sur une intervention de son organisation' do
    assert @policy.saisir_description?
    assert @policy.choisir_adherent?
    assert @policy.planifier_dates?
    assert @policy.saisir_assignation?
    assert @policy.saisir_realisation?
    assert @policy.saisir_commentaires?
    assert @policy.mots_cles_manager?
    assert @policy.cascade_services?
    assert @policy.verifier_disponibilites?
  end

  test 'accès autorisé pour un manager sur un modèle de pointage de son organisation' do
    assert @policy_pointage.show?
    assert @policy_pointage.edit?
    assert @policy_pointage.update?
  end

  test 'affichage autorisé pour un manager sur un modèle de pointage de son organisation' do
    assert @policy_pointage.voir_pointages?
    assert @policy_pointage.voir_agent_des_pointages?
    assert @policy_pointage.voir_qrcode_pointage?
  end

  test 'affichage interdit pour un manager sur un modèle de pointage de son organisation' do
    refute @policy_pointage.voir_realisation?
  end

  test 'saisie interdite pour un manager sur un modèle de pointage de son organisation' do
    refute @policy_pointage.planifier_dates?
    refute @policy_pointage.saisir_realisation?
    refute @policy_pointage.verifier_disponibilites?
  end

  test "accès autorisé pour un manager sur une intervention d'un service qu'il ne gère pas" do
    assert @policy_autre_service.show?
    assert @policy_autre_service.edit?
    assert @policy_autre_service.update?
    assert @policy_autre_service.destroy?
    assert @policy_autre_service.valider?
    assert @policy_autre_service.archiver?
  end

  test "accès interdit pour un manager sur une intervention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.purge?
    refute @policy_autre_org.terminer?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
    refute @policy_autre_org.archiver?
    refute @policy_autre_org.can_see_qrcode_pointage_pdf?
    refute @policy_autre_org.pointer?
  end

  test "affichage interdit pour un manager sur une intervention d'une autre organisation" do
    refute @policy_autre_org.voir_assignation?
    refute @policy_autre_org.voir_realisation?
    refute @policy_autre_org.voir_activite?
    refute @policy_autre_org.voir_dates_prevues?
  end
end
