# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/facture_ligne_test.rb (models symétriques, #330/#333).
class CommandeLigneTest < ActiveSupport::TestCase
  setup do
    @commande = commandes(:commande_secretariat) # total_ht initial 0, sans ligne
    @prestation = prestations(:nettoyage_bureaux) # tarif 25.50
  end

  # --- Validations ---

  test 'la quantité est requise' do
    ligne = CommandeLigne.new(commande: @commande, prestation: @prestation)
    # prix_ht est dérivé de la prestation, seule la qté manque réellement
    refute ligne.valid?
    assert ligne.errors[:qté].any?
  end

  test 'la prestation est requise' do
    ligne = CommandeLigne.new(commande: @commande, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:prestation].any?
  end

  test 'la commande est requise' do
    ligne = CommandeLigne.new(prestation: @prestation, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:commande].any?
  end

  # --- Dérivation du prix ---

  # ⚠ Ce test fige le comportement ACTUEL, qui est aussi le bug B2 du registre
  # (.claude/method/bugs-signales.md) : le prix copié depuis la cotation signée
  # est écrasé par le tarif courant de la prestation. Si la décision métier
  # « respecter le prix du devis » est prise, ce test devra être inversé.
  test 'le prix HT est dérivé de la prestation (jamais saisi) — comportement actuel, cf. bug B2' do
    ligne = CommandeLigne.create!(commande: @commande, prestation: @prestation, qté: 1, prix_ht: 9999)
    assert_equal @prestation.tarif, ligne.reload.prix_ht
  end

  test "sans prestation, le prix HT n'est pas dérivé et reste tel quel" do
    ligne = CommandeLigne.new(commande: @commande, qté: 1, prix_ht: 50)
    ligne.valid? # déclenche le before_validation
    assert_equal 50, ligne.prix_ht
  end

  # --- total_ht (colonne générée) ---

  test 'total_ht de la ligne = qté × tarif de la prestation (colonne générée)' do
    ligne = CommandeLigne.create!(commande: @commande, prestation: @prestation, qté: 4)
    assert_equal (@prestation.tarif * 4).to_f, ligne.reload.total_ht.to_f
  end

  # --- Recalcul du total de la commande ---

  test "le total de la commande est recalculé après l'ajout de lignes" do
    @commande.commande_lignes.create!(prestation: @prestation, qté: 2)                            # 51.00
    @commande.commande_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)  # 30.00
    assert_equal 81.0, @commande.reload.total_ht.to_f
  end

  test "le total de la commande est recalculé après la suppression d'une ligne" do
    @commande.commande_lignes.create!(prestation: @prestation, qté: 2)                            # 51.00
    ligne = @commande.commande_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1) # 30.00
    assert_equal 81.0, @commande.reload.total_ht.to_f

    ligne.destroy
    assert_equal 51.0, @commande.reload.total_ht.to_f
  end
end
