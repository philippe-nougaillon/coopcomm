# frozen_string_literal: true

require 'test_helper'

class FactureLigneTest < ActiveSupport::TestCase
  setup do
    @facture = factures(:facture_secretariat) # total_ht initial 0, sans ligne
    @prestation = prestations(:nettoyage_bureaux) # tarif 25.50
  end

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'une ligne est figé à la transformation de la commande en facture :
  # il ne suit plus le tarif de la prestation. total_ht est une colonne générée.

  # --- Validations ---

  test 'la quantité est requise' do
    ligne = FactureLigne.new(facture: @facture, prestation: @prestation, prix_ht: 25.50)
    refute ligne.valid?
    assert ligne.errors[:qté].any?
  end

  test 'le prix HT est requis' do
    ligne = FactureLigne.new(facture: @facture, prestation: @prestation, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:prix_ht].any?
  end

  test 'la prestation est requise' do
    ligne = FactureLigne.new(facture: @facture, qté: 1, prix_ht: 25.50)
    refute ligne.valid?
    assert ligne.errors[:prestation].any?
  end

  test 'la facture est requise' do
    ligne = FactureLigne.new(prestation: @prestation, qté: 1, prix_ht: 25.50)
    refute ligne.valid?
    assert ligne.errors[:facture].any?
  end

  # --- Prix figé (le prix vient de la commande, jamais du tarif courant) ---

  test 'le prix HT fourni est conservé tel quel et jamais re-dérivé de la prestation' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 1, prix_ht: 9999)
    assert_equal 9999, ligne.reload.prix_ht
  end

  test "une hausse du tarif de la prestation ne modifie pas le prix d'une ligne existante" do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 2, prix_ht: 25.50)

    @prestation.update!(tarif: 40.00)

    assert_equal 25.5, ligne.reload.prix_ht.to_f
    assert_equal 51.0, ligne.total_ht.to_f
    assert_equal 51.0, @facture.reload.total_ht.to_f
  end

  # --- total_ht (colonne générée) ---

  test 'total_ht de la ligne = qté × prix_ht (colonne générée)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 4, prix_ht: 12.50)
    assert_equal 50.0, ligne.reload.total_ht.to_f
  end

  # --- Recalcul du total de la facture ---

  test "le total de la facture est recalculé après l'ajout de lignes" do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)                            # 51.00
    @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)  # 30.00
    assert_equal 81.0, @facture.reload.total_ht.to_f
  end

  test "le total de la facture est recalculé après la suppression d'une ligne" do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)                            # 51.00
    ligne = @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00) # 30.00
    assert_equal 81.0, @facture.reload.total_ht.to_f

    ligne.destroy
    assert_equal 51.0, @facture.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================
end
