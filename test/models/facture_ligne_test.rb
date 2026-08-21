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

  test 'prix_ht : prix repris de la commande → conservé tel quel, jamais re-dérivé (critique)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 1, prix_ht: 9999)

    assert_equal 9999, ligne.reload.prix_ht
  end

  test 'prix_ht : hausse du tarif de la prestation → ligne et total inchangés (critique)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 2, prix_ht: 25.50)

    @prestation.update!(tarif: 40.00)

    assert_equal 25.5, ligne.reload.prix_ht.to_f
    assert_equal 51.0, ligne.total_ht.to_f
    assert_equal 51.0, @facture.reload.total_ht.to_f
  end

  test 'total_ht : qté et prix_ht → produit calculé par la colonne générée (critique)' do
    ligne = FactureLigne.create!(facture: @facture, prestation: @prestation, qté: 4, prix_ht: 12.50)

    assert_equal 50.0, ligne.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'refresh_facture_total : lignes ajoutées → total de la facture recalculé' do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)

    assert_equal 81.0, @facture.reload.total_ht.to_f
  end

  test 'refresh_facture_total : ligne supprimée → total de la facture recalculé' do
    @facture.facture_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    ligne = @facture.facture_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)

    ligne.destroy

    assert_equal 51.0, @facture.reload.total_ht.to_f
  end
end
