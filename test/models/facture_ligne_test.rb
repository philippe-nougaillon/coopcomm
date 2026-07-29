# frozen_string_literal: true

require 'test_helper'

# ==================== TESTS CRITIQUES ====================
# Le prix d'une ligne est toujours dérivé du tarif
# de la prestation (jamais saisi), total_ht est une colonne générée.
class FactureLigneTest < ActiveSupport::TestCase
  setup do
    @facture = factures(:facture_secretariat) # total_ht initial 0, sans ligne
    @prestation = prestations(:nettoyage_bureaux) # tarif 25.50
  end

  # --- Validations ---

  test 'la quantité est requise' do
    ligne = FactureLigne.new(facture: @facture, prestation: @prestation)
    # prix_ht est dérivé de la prestation, seule la qté manque réellement
    refute ligne.valid?
    assert ligne.errors[:qté].any?
  end

  test 'la prestation est requise' do
    ligne = FactureLigne.new(facture: @facture, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:prestation].any?
  end

  test 'la facture est requise' do
    ligne = FactureLigne.new(prestation: @prestation, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:facture].any?
  end

  # --- Dérivation du prix ---

  test 'le prix HT est dérivé de la prestation (jamais saisi)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 1, prix_ht: 9999)
    assert_equal @prestation.tarif, ligne.reload.prix_ht
  end

  test "sans prestation, le prix HT n'est pas dérivé et reste tel quel" do
    ligne = FactureLigne.new(facture: @facture, qté: 1, prix_ht: 50)
    ligne.valid? # déclenche le before_validation
    assert_equal 50, ligne.prix_ht
  end

  # --- total_ht (colonne générée) ---

  test 'total_ht de la ligne = qté × tarif de la prestation (colonne générée)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 4)
    assert_equal (@prestation.tarif * 4).to_f, ligne.reload.total_ht.to_f
  end

  # --- Recalcul du total de la facture ---

  test "le total de la facture est recalculé après l'ajout de lignes" do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2)                            # 51.00
    @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)  # 30.00
    assert_equal 81.0, @facture.reload.total_ht.to_f
  end

  test "le total de la facture est recalculé après la suppression d'une ligne" do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2)                            # 51.00
    ligne = @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1) # 30.00
    assert_equal 81.0, @facture.reload.total_ht.to_f

    ligne.destroy
    assert_equal 51.0, @facture.reload.total_ht.to_f
  end
end
