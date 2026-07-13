# frozen_string_literal: true

require 'test_helper'

class CreateFactureFromCommandeTest < ActiveSupport::TestCase
  setup do
    @commande = commandes(:commande_paris) # informatique, 1 ligne (nettoyage_bureaux, qté 3)
  end

  test 'retourne une Facture non sauvegardée' do
    facture = CreateFactureFromCommande.new(@commande).call
    assert_instance_of Facture, facture
    assert facture.new_record?
  end

  test 'recopie les attributs de la commande' do
    facture = CreateFactureFromCommande.new(@commande).call
    assert_equal @commande.adherent_id, facture.adherent_id
    assert_equal @commande.service_id, facture.service_id
    assert_equal @commande.intitulé, facture.intitulé
    assert_equal @commande.mémo, facture.mémo
    assert_equal @commande.date_livraison_souhaitée, facture.date_livraison_souhaitée
  end

  test 'construit une ligne de facture par ligne de commande' do
    facture = CreateFactureFromCommande.new(@commande).call
    assert_equal @commande.commande_lignes.size, facture.facture_lignes.size
    ligne_source = @commande.commande_lignes.first
    ligne_copie = facture.facture_lignes.first
    assert_equal ligne_source.prestation_id, ligne_copie.prestation_id
    assert_equal ligne_source.qté, ligne_copie.qté
  end

  test 'la facture construite persiste et recalcule son total' do
    facture = CreateFactureFromCommande.new(@commande).call
    assert facture.save, facture.errors.full_messages.to_sentence
    # prix_ht est re-dérivé de la prestation (25.50) × qté 3 = 76.50
    assert_equal 76.5, facture.reload.total_ht.to_f
    assert_equal 1, facture.facture_lignes.count
  end

  test "la facture construite reçoit une ref et l'état initial à la sauvegarde" do
    facture = CreateFactureFromCommande.new(@commande).call
    assert_nil facture.ref
    facture.save!
    assert facture.ref.present?
    assert facture.créé?
  end

  test 'expose une interface de service via ApplicationService.call' do
    facture = CreateFactureFromCommande.call(@commande)
    assert_instance_of Facture, facture
  end
end
