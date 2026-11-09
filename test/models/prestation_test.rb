# frozen_string_literal: true

require 'test_helper'

class PrestationTest < ActiveSupport::TestCase
  setup do
    @org = organisations(:mairie_paris)
  end

  test 'une prestation dont le code existe déjà dans la même organisation est refusée' do
    Prestation.create!(organisation: @org, code: 'DUP', libellé: 'x', tarif: 5, unité: 'Heure(s)')
    doublon = Prestation.new(organisation: @org, code: 'DUP', libellé: 'y', tarif: 6, unité: 'Heure(s)')

    assert_not doublon.valid?
  end

  test 'une prestation dont le code existe dans une autre organisation est acceptée' do
    Prestation.create!(organisation: @org, code: 'SHARED', libellé: 'x', tarif: 5, unité: 'Heure(s)')
    autre = Prestation.new(organisation: organisations(:mairie_marseille), code: 'SHARED', libellé: 'y', tarif: 6,
                           unité: 'Heure(s)')

    assert autre.valid?
  end

  test 'le code de prestation est mis en majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'abc12', libellé: 'x', tarif: 5, unité: 'Heure(s)')

    assert_equal 'ABC12', prestation.code
  end

  test 'la catégorie de prestation est mise en majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'CAT1', libellé: 'x', tarif: 5, unité: 'Heure(s)',
                                    catégorie: 'entretien')

    assert_equal 'ENTRETIEN', prestation.catégorie
  end

  test 'la sous-catégorie de prestation est mise en majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'CAT2', libellé: 'x', tarif: 5, unité: 'Heure(s)',
                                    sous_catégorie: 'vitres')

    assert_equal 'VITRES', prestation.sous_catégorie
  end

  test "l'unité de prestation est détourée de ses espaces" do
    prestation = Prestation.create!(organisation: @org, code: 'UNI1', libellé: 'x', tarif: 5, unité: '  heure  ')

    assert_equal 'heure', prestation.unité
  end

  test "une unité de prestation faite d'espaces devient nulle" do
    prestation = Prestation.new(organisation: @org, code: 'UNI2', libellé: 'x', tarif: 5, unité: '   ')

    assert_nil prestation.unité
  end

  test 'les prestations sont triées par code' do
    codes = Prestation.where(organisation: @org).ordered.pluck(:code)

    assert_equal codes.sort, codes
  end

  test "une prestation s'affiche avec son code, son libellé et son tarif sur une seule ligne" do
    prestation = Prestation.new(code: 'NET01', libellé: 'Nettoyage', tarif: 25.5)

    assert_equal 'NET01 → Nettoyage (25.5 € HT)', prestation.display_name
  end
end
