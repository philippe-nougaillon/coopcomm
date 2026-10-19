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

  test 'le prix saisi sur une ligne de cotation est écrasé par le tarif de la prestation choisie (critique)' do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 1, prix_ht: 9999)

    assert_equal @prestation.tarif, ligne.reload.prix_ht
  end

  test 'le prix saisi sur une ligne de cotation sans prestation reste tel quel (critique)' do
    ligne = CotationLigne.new(cotation: @cotation, qté: 1, prix_ht: 50)

    ligne.valid?

    assert_equal 50, ligne.prix_ht
  end

  test "le total d'une ligne de cotation est le produit de la quantité par le tarif, calculé par la colonne générée (critique)" do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 4)

    assert_equal (@prestation.tarif * 4).to_f, ligne.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le total de la cotation est recalculé lorsque des lignes sont ajoutées' do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)
    @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)

    assert_equal 81.0, @cotation.reload.total_ht.to_f
  end

  test 'un total de cotation au-delà du million est conservé sans débordement' do
    presta = Prestation.create!(organisation: organisations(:mairie_paris), code: 'BIG01', libellé: 'Gros lot',
                                unité: 'Forfait', tarif: 600_000)

    @cotation.cotation_lignes.create!(prestation: presta, qté: 2)

    assert_equal 1_200_000.0, @cotation.reload.total_ht.to_f
  end

  test "le total de la cotation est recalculé lorsqu'une ligne est supprimée" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)
    ligne = @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)

    ligne.destroy

    assert_equal 51.0, @cotation.reload.total_ht.to_f
  end

  # Gardes de cohérence des fixtures : un tarif modifié sans mettre à jour les valeurs
  # dérivées figées devient un échec explicite au lieu d'une dérive silencieuse.

  test "le prix d'une ligne de cotation est égal au tarif de sa prestation (fixtures)" do
    ligne = cotation_lignes(:ligne_cotation_paris)

    assert_equal ligne.prestation.tarif, ligne.prix_ht
  end

  test "le total d'une cotation est la somme de ses lignes (fixtures)" do
    cotation = cotations(:cotation_paris)

    assert_equal cotation.cotation_lignes.sum(&:total_ht), cotation.total_ht
  end
end
