# frozen_string_literal: true

require 'test_helper'

class AdherentInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    intervention = interventions(:tonte_locaux)
    intervention_pointage = interventions(:intervention_repete)
    intervention_autre_adherent = interventions(:intervention_paris)
    intervention_autre_org = interventions(:nettoyage_port)

    @policy = InterventionPolicy.new(adherent, intervention)
    @policy_pointage = InterventionPolicy.new(adherent, intervention_pointage)
    @policy_autre_adherent = InterventionPolicy.new(adherent, intervention_autre_adherent)
    @policy_autre_org = InterventionPolicy.new(adherent, intervention_autre_org)
  end

  test 'accès autorisé pour un adhérent sur une intervention dont il est le demandeur' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.purge?
    assert @policy.purger_photos_demande?
    assert @policy.valider?
    assert @policy.refuser?
    assert @policy.can_see_qrcode_pointage_pdf?
    assert @policy.get_unavailable_elements?
    assert @policy.services_for_adherent?
    assert @policy.agents_for_service?
  end

  test 'accès interdit pour un adhérent sur une intervention dont il est le demandeur' do
    refute @policy.destroy?
    refute @policy.fiche?
    refute @policy.terminer?
    refute @policy.archiver?
    refute @policy.pointer?
    refute @policy.pointage_statut?
    refute @policy.update_location?
    refute @policy.new_intervention_modele_pointage?
    refute @policy.create_intervention_modele_pointage?
  end

  test 'affichage autorisé pour un adhérent sur une intervention dont il est le demandeur' do
    assert @policy.voir_assignation?
    assert @policy.voir_dates_prevues?
    assert @policy.voir_temps?
    assert @policy.voir_compte_rendu?
  end

  test 'affichage interdit pour un adhérent sur une intervention dont il est le demandeur' do
    refute @policy.voir_realisation?
    refute @policy.voir_pointages?
    refute @policy.voir_activite?
    refute @policy.voir_qrcode_pointage?
    refute @policy.voir_agent_des_pointages?
  end

  test 'saisie autorisée pour un adhérent sur une intervention dont il est le demandeur' do
    assert @policy.saisir_description?
    assert @policy.planifier_dates?
  end

  test 'saisie interdite pour un adhérent sur une intervention dont il est le demandeur' do
    refute @policy.choisir_adherent?
    refute @policy.saisir_assignation?
    refute @policy.saisir_realisation?
    refute @policy.saisir_commentaires?
    refute @policy.mots_cles_manager?
    refute @policy.cascade_services?
    refute @policy.verifier_disponibilites?
  end

  test 'accès autorisé pour un adhérent sur un modèle de pointage dont il est le demandeur' do
    assert @policy_pointage.show?
    assert @policy_pointage.edit?
    assert @policy_pointage.update?
    assert @policy_pointage.valider?
    assert @policy_pointage.refuser?
  end

  test 'affichage autorisé pour un adhérent sur un modèle de pointage dont il est le demandeur' do
    assert @policy_pointage.voir_pointages?
    assert @policy_pointage.voir_agent_des_pointages?
    assert @policy_pointage.voir_qrcode_pointage?
  end

  test 'affichage interdit pour un adhérent sur un modèle de pointage dont il est le demandeur' do
    refute @policy_pointage.voir_realisation?
    refute @policy_pointage.voir_temps?
  end

  test 'saisie interdite pour un adhérent sur un modèle de pointage dont il est le demandeur' do
    refute @policy_pointage.planifier_dates?
    refute @policy_pointage.saisir_realisation?
  end

  test "accès interdit pour un adhérent sur une intervention d'un autre demandeur" do
    refute @policy_autre_adherent.show?
    refute @policy_autre_adherent.edit?
    refute @policy_autre_adherent.update?
    refute @policy_autre_adherent.purge?
    refute @policy_autre_adherent.valider?
    refute @policy_autre_adherent.refuser?
  end

  test "accès interdit pour un adhérent sur une intervention d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.purge?
    refute @policy_autre_org.valider?
    refute @policy_autre_org.refuser?
  end

  test "affichage interdit pour un adhérent sur une intervention d'une autre organisation" do
    refute @policy_autre_org.voir_assignation?
    refute @policy_autre_org.voir_temps?
    refute @policy_autre_org.voir_dates_prevues?
  end
end
