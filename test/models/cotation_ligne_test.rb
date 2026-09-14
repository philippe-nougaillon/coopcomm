# frozen_string_literal: true

require 'test_helper'

class CotationLigneTest < ActiveSupport::TestCase
  setup do
    @cotation = cotations(:cotation_secretariat)
    @prestation = prestations(:nettoyage_bureaux)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'une ligne de devis n'est jamais saisi : il vient du tarif de la prestation,
  # et total_ht est une colonne générée par la base. Une dérive ici fausse le montant
  # envoyé à la commune.

  test 'set_prix_from_prestation : prestation choisie → le prix saisi est écrasé par le tarif (critique)' do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 1, prix_ht: 9999)

    assert_equal @prestation.tarif, ligne.reload.prix_ht
  end

  test 'set_prix_from_prestation : sans prestation → le prix reste tel quel (critique)' do
    ligne = CotationLigne.new(cotation: @cotation, qté: 1, prix_ht: 50)

    ligne.valid?

    assert_equal 50, ligne.prix_ht
  end

  test 'total_ht : qté et tarif → produit calculé par la colonne générée (critique)' do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 4)

    assert_equal (@prestation.tarif * 4).to_f, ligne.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'refresh_cotation_total : lignes ajoutées → total de la cotation recalculé' do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)
    @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)

    assert_equal 81.0, @cotation.reload.total_ht.to_f
  end

  test 'refresh_cotation_total : montant au-delà du million → total conservé sans débordement' do
    presta = Prestation.create!(organisation: organisations(:mairie_paris), code: 'BIG01', libellé: 'Gros lot',
                                unité: 'Forfait', tarif: 600_000)

    @cotation.cotation_lignes.create!(prestation: presta, qté: 2)

    assert_equal 1_200_000.0, @cotation.reload.total_ht.to_f
  end

  test 'refresh_cotation_total : ligne supprimée → total de la cotation recalculé' do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)
    ligne = @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)

    ligne.destroy

    assert_equal 51.0, @cotation.reload.total_ht.to_f
  end

  # Gardes de cohérence des fixtures : un tarif modifié sans mettre à jour les valeurs
  # dérivées figées devient un échec explicite au lieu d'une dérive silencieuse.

  test 'fixtures : prix_ht d\'une ligne → égal au tarif de sa prestation' do
    ligne = cotation_lignes(:ligne_cotation_paris)

    assert_equal ligne.prestation.tarif, ligne.prix_ht
  end

  test 'fixtures : total_ht d\'une cotation → somme de ses lignes' do
    cotation = cotations(:cotation_paris)

    assert_equal cotation.cotation_lignes.sum(&:total_ht), cotation.total_ht
  end
end
