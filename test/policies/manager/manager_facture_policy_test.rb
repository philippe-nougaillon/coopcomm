# frozen_string_literal: true

require 'test_helper'

class ManagerFacturePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:manager_paris) # gère service_paris et secretariat

    facture_son_service = factures(:facture_secretariat) # service: secretariat, état « envoyé »
    facture_autre_service = factures(:facture_paris)      # service: informatique
    facture_autre_org = factures(:facture_marseille)      # mairie_marseille

    @policy = FacturePolicy.new(@manager, facture_son_service)
    @policy_autre_service = FacturePolicy.new(@manager, facture_autre_service)
    @policy_autre_org = FacturePolicy.new(@manager, facture_autre_org)
  end

  test 'index autorisé pour un manager' do
    assert @policy.index?
  end

  test 'show / destroy / pdf autorisés sur une facture de son service' do
    assert @policy.show?
    assert @policy.destroy?
    assert @policy.pdf?
  end

  test 'transitions autorisées sur une facture de son service' do
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  # --- Verrou d'édition selon l'état (modifiable?) ---

  test 'update interdit sur une facture envoyée de son service' do
    # facture_secretariat est à l'état « envoyé » (non modifiable)
    refute @policy.update?
    refute @policy.edit?
  end

  test 'update autorisé sur une facture modifiable (créé) de son service' do
    facture_creee = Facture.new(service: services(:secretariat), adherent: users(:weil), intitulé: 'Brouillon')
    policy = FacturePolicy.new(@manager, facture_creee)
    assert policy.update?
    assert policy.edit?
  end

  test "accès interdit sur une facture d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.pdf?
  end

  test "accès interdit sur une facture d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.destroy?
  end
end
