require "test_helper"

class CotationLigneTest < ActiveSupport::TestCase
  setup do
    @cotation = cotations(:cotation_secretariat) # total_ht initial 0, sans ligne
    @prestation = prestations(:nettoyage_bureaux)
  end

  test "qté et prix_ht sont requis" do
    ligne = CotationLigne.new(cotation: @cotation, prestation: @prestation)
    refute ligne.valid?
    assert ligne.errors[:qté].any?
    assert ligne.errors[:prix_ht].any?
  end

  test "total_ht de la ligne = qté × prix_ht (colonne générée)" do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 4, prix_ht: 12.5)
    assert_equal 50.0, ligne.reload.total_ht.to_f
  end

  test "le total de la cotation est recalculé après l'ajout de lignes" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 10)
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 1, prix_ht: 5)
    assert_equal 25.0, @cotation.reload.total_ht.to_f
  end

  test "le total de la cotation supporte les montants > 999 999,99 (précision alignée sur les lignes)" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 3, prix_ht: 500_000)
    assert_equal 1_500_000.0, @cotation.reload.total_ht.to_f
  end

  test "le total de la cotation est recalculé après la suppression d'une ligne" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2, prix_ht: 10)
    ligne = @cotation.cotation_lignes.create!(prestation: @prestation, qté: 1, prix_ht: 5)
    assert_equal 25.0, @cotation.reload.total_ht.to_f

    ligne.destroy
    assert_equal 20.0, @cotation.reload.total_ht.to_f
  end
end
