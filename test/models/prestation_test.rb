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
end
