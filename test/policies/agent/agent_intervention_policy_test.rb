# frozen_string_literal: true

require 'test_helper'

class AgentInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    intervention = interventions(:intervention_paris)
    intervention_pointage = interventions(:intervention_repete)
    intervention_non_affectée = interventions(:tonte_locaux)
    intervention_autre_org = interventions(:nettoyage_port)

    @policy = InterventionPolicy.new(agent, intervention)
    @policy_pointage = InterventionPolicy.new(agent, intervention_pointage)
    @policy_non_affectée = InterventionPolicy.new(agent, intervention_non_affectée)
    @policy_autre_org = InterventionPolicy.new(agent, intervention_autre_org)
  end

  test 'accès autorisé pour un agent sur une intervention à laquelle il est affecté' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.purge?
    assert @policy.terminer?
    assert @policy.pointer?
    assert @policy.pointage_statut?
    assert @policy.update_location?
    assert @policy.get_unavailable_elements?
    assert @policy.services_for_adherent?
    assert @policy.agents_for_service?
  end

  test 'accès interdit pour un agent sur une intervention à laquelle il est affecté' do
    refute @policy.destroy?
    refute @policy.purger_photos_demande?
    refute @policy.valider?
    refute @policy.refuser?
    refute @policy.archiver?
    refute @policy.can_see_qrcode_pointage_pdf?
    refute @policy.new_intervention_modele_pointage?
    refute @policy.create_intervention_modele_pointage?
  end

  test 'affichage autorisé pour un agent sur une intervention à laquelle il est affecté' do
    assert @policy.voir_assignation?
    assert @policy.voir_realisation?
    assert @policy.voir_dates_prevues?
  end

  test 'affichage interdit pour un agent sur une intervention à laquelle il est affecté' do
    refute @policy.voir_activite?
    refute @policy.voir_pointages?
    refute @policy.voir_agent_des_pointages?
    refute @policy.voir_qrcode_pointage?
    refute @policy.voir_temps?
    refute @policy.voir_compte_rendu?
  end

  test 'saisie autorisée pour un agent sur une intervention à laquelle il est affecté' do
    assert @policy.choisir_adherent?
    assert @policy.saisir_assignation?
    assert @policy.saisir_realisation?
    assert @policy.saisir_commentaires?
    assert @policy.verifier_disponibilites?
  end

  test 'saisie interdite pour un agent sur une intervention à laquelle il est affecté' do
    refute @policy.saisir_description?
    refute @policy.planifier_dates?
    refute @policy.mots_cles_manager?
    refute @policy.cascade_services?
  end

  test 'accès autorisé pour un agent sur un modèle de pointage auquel il est affecté' do
    assert @policy_pointage.show?
    assert @policy_pointage.terminer?
    assert @policy_pointage.purge?
    assert @policy_pointage.pointer?
    assert @policy_pointage.pointage_statut?
    assert @policy_pointage.update_location?
  end

  test 'accès interdit pour un agent sur un modèle de pointage auquel il est affecté' do
    refute @policy_pointage.edit?
    refute @policy_pointage.update?
  end

  test 'affichage autorisé pour un agent sur un modèle de pointage auquel il est affecté' do
    assert @policy_pointage.voir_pointages?
  end

  test 'affichage interdit pour un agent sur un modèle de pointage auquel il est affecté' do
    refute @policy_pointage.voir_agent_des_pointages?
    refute @policy_pointage.voir_realisation?
  end

  test 'saisie interdite pour un agent sur un modèle de pointage auquel il est affecté' do
    refute @policy_pointage.planifier_dates?
    refute @policy_pointage.saisir_realisation?
    refute @policy_pointage.verifier_disponibilites?
  end

  test "accès interdit pour un agent sur une intervention à laquelle il n'est pas affecté" do
    refute @policy_non_affectée.show?
    refute @policy_non_affectée.edit?
    refute @policy_non_affectée.update?
    refute @policy_non_affectée.destroy?
    refute @policy_non_affectée.purge?
    refute @policy_non_affectée.terminer?
    refute @policy_non_affectée.pointer?
    refute @policy_non_affectée.pointage_statut?
    refute @policy_non_affectée.update_location?
  end

  test "accès interdit pour un agent sur une intervention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.purge?
    refute @policy_autre_org.terminer?
    refute @policy_autre_org.pointer?
  end

  test "affichage interdit pour un agent sur une intervention d'une autre organisation" do
    refute @policy_autre_org.voir_assignation?
    refute @policy_autre_org.voir_realisation?
    refute @policy_autre_org.voir_dates_prevues?
  end
end
