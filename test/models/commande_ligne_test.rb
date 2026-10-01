# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/facture_ligne_test.rb (modèles symétriques).
class CommandeLigneTest < ActiveSupport::TestCase
  setup do
    @commande = commandes(:commande_secretariat)
    @prestation = prestations(:nettoyage_bureaux)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'une ligne de commande est figé à la transformation du devis : il ne suit
  # plus le tarif de la prestation. total_ht est une colonne générée.

  test "le prix d'une ligne de commande repris du devis est conservé tel quel, jamais écrasé par le tarif de la prestation (critique)" do
    ligne = CommandeLigne.create!(commande: @commande, prestation: @prestation, qté: 1, prix_ht: 9999)

    assert_equal 9999, ligne.reload.prix_ht
  end

  test 'une hausse du tarif de la prestation ne change ni le prix de la ligne de commande ni le total de la commande (critique)' do
    ligne = CommandeLigne.create!(commande: @commande, prestation: @prestation, qté: 2, prix_ht: 25.50)

    @prestation.update!(tarif: 40.00)

    assert_equal 25.5, ligne.reload.prix_ht.to_f
    assert_equal 51.0, ligne.total_ht.to_f
    assert_equal 51.0, @commande.reload.total_ht.to_f
  end

  test "le total d'une ligne de commande est le produit de la quantité par le prix, calculé par la colonne générée (critique)" do
    ligne = CommandeLigne.create!(commande: @commande, prestation: @prestation, qté: 4, prix_ht: 12.50)

    assert_equal 50.0, ligne.reload.total_ht.to_f
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le total de la commande est recalculé lorsque des lignes sont ajoutées' do
    @commande.commande_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    @commande.commande_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1, prix_ht: 30.00)

    assert_equal 81.0, @commande.reload.total_ht.to_f
  end

  test "le total de la commande est recalculé lorsqu'une ligne est supprimée" do
    @commande.commande_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 25.50)
    ligne = @commande.commande_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1,
                                              prix_ht: 30.00)

    ligne.destroy

    assert_equal 51.0, @commande.reload.total_ht.to_f
  end
end
