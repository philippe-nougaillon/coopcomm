# frozen_string_literal: true

require 'test_helper'

class FactureLigneTest < ActiveSupport::TestCase
  setup do
    @facture = factures(:facture_secretariat)
    @prestation = prestations(:nettoyage_bureaux)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'une ligne est figé à la transformation de la commande en facture : il ne
  # suit plus le tarif de la prestation. total_ht est une colonne générée.

  test "le prix d'une ligne de facture repris de la commande est conservé tel quel, jamais écrasé par le tarif de la prestation (critique)" do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 1, prix_ht: 9999)

    assert_equal 9999, ligne.reload.prix_ht
  end

  test 'une hausse du tarif de la prestation ne change ni le prix de la ligne de facture ni le total de la facture (critique)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 2, prix_ht: 25.50)

    @prestation.update!(tarif: 40.00)

    assert_equal 25.5, ligne.reload.prix_ht.to_f
    assert_equal 51.0, ligne.total_ht.to_f
    assert_equal 51.0, @facture.reload.total_ht.to_f
  end

  test "le total d'une ligne de facture est le produit de la quantité par le prix, calculé par la colonne générée (critique)" do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 4, prix_ht: 12.50)

    assert_equal 50.0, ligne.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le total de la facture est recalculé lorsque des lignes sont ajoutées' do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)

    assert_equal 81.0, @facture.reload.total_ht.to_f
  end

  test "le total de la facture est recalculé lorsqu'une ligne est supprimée" do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    ligne = @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)

    ligne.destroy

    assert_equal 51.0, @facture.reload.total_ht.to_f
  end
end
