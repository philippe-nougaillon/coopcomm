require "test_helper"

class PrestationTest < ActiveSupport::TestCase
  setup do
    @org = organisations(:mairie_paris)
  end

  test "valide avec code, libellé et tarif" do
    prestation = Prestation.new(organisation: @org, code: "ABC", libellé: "Test", tarif: 10)
    assert prestation.valid?
  end

  test "invalide sans code, libellé ni tarif" do
    prestation = Prestation.new(organisation: @org)
    refute prestation.valid?
    assert prestation.errors[:code].any?
    assert prestation.errors[:libellé].any?
    assert prestation.errors[:tarif].any?
  end

  test "le code est normalisé en majuscules" do
    prestation = Prestation.create!(organisation: @org, code: "abc12", libellé: "x", tarif: 5)
    assert_equal "ABC12", prestation.code
  end

  test "le code est unique au sein d'une organisation" do
    Prestation.create!(organisation: @org, code: "DUP", libellé: "x", tarif: 5)
    doublon = Prestation.new(organisation: @org, code: "DUP", libellé: "y", tarif: 6)
    refute doublon.valid?
  end

  test "un même code est autorisé dans une autre organisation" do
    Prestation.create!(organisation: @org, code: "SHARED", libellé: "x", tarif: 5)
    autre = Prestation.new(organisation: organisations(:mairie_marseille), code: "SHARED", libellé: "y", tarif: 6)
    assert autre.valid?
  end

  test "display_name" do
    prestation = Prestation.new(code: "NET01", libellé: "Nettoyage", tarif: 25.5)
    assert_equal "NET01 → Nettoyage (25.5 € HT)", prestation.display_name
  end

  # --- Normalisations ---

  test "la catégorie est normalisée en majuscules" do
    prestation = Prestation.create!(organisation: @org, code: "CAT1", libellé: "x", tarif: 5, catégorie: "entretien")
    assert_equal "ENTRETIEN", prestation.catégorie
  end

  test "la sous-catégorie est normalisée en majuscules" do
    prestation = Prestation.create!(organisation: @org, code: "CAT2", libellé: "x", tarif: 5, sous_catégorie: "vitres")
    assert_equal "VITRES", prestation.sous_catégorie
  end

  # --- Scope ---

  test "ordered trie les prestations par code" do
    codes = Prestation.where(organisation: @org).ordered.pluck(:code)
    assert_equal codes.sort, codes
  end

  # --- Suppression contrainte (dependent: :restrict_with_error) ---

  test "destruction refusée quand la prestation est utilisée dans une cotation" do
    presta = prestations(:nettoyage_bureaux) # utilisée par la ligne ligne_cotation_paris
    assert_no_difference -> { Prestation.count } do
      refute presta.destroy
    end
    assert presta.errors[:base].any?
  end

  test "destruction autorisée quand la prestation n'est pas utilisée" do
    presta = prestations(:entretien_espaces_verts) # aucune ligne en fixture
    assert_difference -> { Prestation.count }, -1 do
      assert presta.destroy
    end
  end

  # --- Audit ---

  test "auditée à la création" do
    presta = Prestation.create!(organisation: @org, code: "AUD1", libellé: "x", tarif: 5)
    assert_equal 1, presta.audits.count
    assert_equal "create", presta.audits.last.action
  end
end
