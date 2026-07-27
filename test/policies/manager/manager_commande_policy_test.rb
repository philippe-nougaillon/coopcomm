# frozen_string_literal: true

require 'test_helper'

# Miroir de manager_facture_policy_test.rb (+ create_facture?, règle propre aux commandes).
class ManagerCommandePolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:manager_paris) # gère service_paris et secretariat

    @commande_son_service = commandes(:commande_secretariat) # service: secretariat, état « envoyé »
    commande_autre_service = commandes(:commande_paris)      # service: informatique
    commande_autre_org = commandes(:commande_marseille)      # mairie_marseille

    @policy = CommandePolicy.new(@manager, @commande_son_service)
    @policy_autre_service = CommandePolicy.new(@manager, commande_autre_service)
    @policy_autre_org = CommandePolicy.new(@manager, commande_autre_org)
  end

  test 'index autorisé pour un manager' do
    assert @policy.index?
  end

  test 'show / destroy / pdf autorisés sur une commande de son service' do
    assert @policy.show?
    assert @policy.destroy?
    assert @policy.pdf?
  end

  test 'transitions autorisées sur une commande de son service' do
    assert @policy.envoyer?
    assert @policy.valider?
    assert @policy.refuser?
  end

  # --- Verrou d'édition selon l'état (modifiable?) ---

  test 'update interdit sur une commande envoyée de son service' do
    # commande_secretariat est à l'état « envoyé » (non modifiable)
    refute @policy.update?
    refute @policy.edit?
  end

  test 'update autorisé sur une commande modifiable (créé) de son service' do
    commande_creee = Commande.new(service: services(:secretariat), adherent: users(:weil), intitulé: 'Brouillon')
    policy = CommandePolicy.new(@manager, commande_creee)
    assert policy.update?
    assert policy.edit?
  end

  # --- create_facture? (manage? && validé?) ---

  test 'create_facture interdit tant que la commande de son service n\'est pas validée' do
    refute @policy.create_facture? # état « envoyé »
  end

  test 'create_facture autorisé sur une commande validée de son service' do
    @commande_son_service.update!(workflow_state: Commande::VALIDE)
    policy = CommandePolicy.new(@manager, Commande.find(@commande_son_service.id))
    assert policy.create_facture?
  end

  test 'create_facture interdit sur une commande validée d\'un service qu\'il ne gère pas' do
    commandes(:commande_paris).update!(workflow_state: Commande::VALIDE)
    policy = CommandePolicy.new(@manager, Commande.find(commandes(:commande_paris).id))
    refute policy.create_facture?
  end

  # --- Hors périmètre ---

  test "accès interdit sur une commande d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.pdf?
  end

  test "accès interdit sur une commande d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.destroy?
  end
end
