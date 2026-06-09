require "test_helper"

class CotationLigneTest < ActiveSupport::TestCase
  setup do
    @cotation = cotations(:cotation_secretariat) # total_ht initial 0, sans ligne
    @prestation = prestations(:nettoyage_bureaux) # tarif 25.50
  end

  test "la quantité est requise" do
    ligne = CotationLigne.new(cotation: @cotation, prestation: @prestation)
    refute ligne.valid?
    assert ligne.errors[:qté].any?
  end

  test "le prix HT est dérivé de la prestation (jamais saisi)" do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 1, prix_ht: 9999)
    assert_equal @prestation.tarif, ligne.reload.prix_ht
  end

  test "total_ht de la ligne = qté × tarif de la prestation (colonne générée)" do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 4)
    assert_equal (@prestation.tarif * 4).to_f, ligne.reload.total_ht.to_f
  end

  test "le total de la cotation est recalculé après l'ajout de lignes" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)                                # 51.00
    @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1)      # 30.00
    assert_equal 81.0, @cotation.reload.total_ht.to_f
  end

  test "le total supporte les montants > 999 999,99 (précision alignée sur les lignes)" do
    presta = Prestation.create!(organisation: organisations(:mairie_paris), code: "BIG01", libellé: "Gros lot", tarif: 600_000)
    @cotation.cotation_lignes.create!(prestation: presta, qté: 2)
    assert_equal 1_200_000.0, @cotation.reload.total_ht.to_f
  end

  test "le total de la cotation est recalculé après la suppression d'une ligne" do
    @cotation.cotation_lignes.create!(prestation: @prestation, qté: 2)                                # 51.00
    ligne = @cotation.cotation_lignes.create!(prestation: prestations(:entretien_espaces_verts), qté: 1) # 30.00
    assert_equal 81.0, @cotation.reload.total_ht.to_f

    ligne.destroy
    assert_equal 51.0, @cotation.reload.total_ht.to_f
  end

  # --- Associations requises ---

  test "la prestation est requise" do
    ligne = CotationLigne.new(cotation: @cotation, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:prestation].any?
  end

  test "la cotation est requise" do
    ligne = CotationLigne.new(prestation: @prestation, qté: 1)
    refute ligne.valid?
    assert ligne.errors[:cotation].any?
  end

  test "sans prestation, le prix HT n'est pas dérivé et reste tel quel" do
    ligne = CotationLigne.new(cotation: @cotation, qté: 1, prix_ht: 50)
    ligne.valid? # déclenche le before_validation
    assert_equal 50, ligne.prix_ht
  end

  # --- Audit (associé à la cotation) ---

  test "auditée et associée à la cotation" do
    ligne = CotationLigne.create!(cotation: @cotation, prestation: @prestation, qté: 1)
    assert_equal 1, ligne.audits.count
    assert_equal "create", ligne.audits.last.action
    assert_equal @cotation, ligne.audits.last.associated
  end

  # --- Cohérence des fixtures (valeurs dérivées figées en dur) ---
  # Ces deux gardes transforment une dérive silencieuse (tarif modifié sans
  # mettre à jour les fixtures) en échec de test explicite.

  test "fixtures cohérentes : prix_ht de la ligne = tarif de la prestation" do
    ligne = cotation_lignes(:ligne_cotation_paris)
    assert_equal ligne.prestation.tarif, ligne.prix_ht
  end

  test "fixtures cohérentes : total_ht de cotation_paris = somme de ses lignes" do
    cotation = cotations(:cotation_paris)
    assert_equal cotation.cotation_lignes.sum(&:total_ht), cotation.total_ht
  end
end
