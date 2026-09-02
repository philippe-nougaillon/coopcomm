# frozen_string_literal: true

require 'test_helper'

class PrestationTest < ActiveSupport::TestCase
  setup do
    @org = organisations(:mairie_paris)
  end

  test 'unicité du code : doublon dans la même organisation → refusé' do
    Prestation.create!(organisation: @org, code: 'DUP', libellé: 'x', tarif: 5, unité: 'Heure(s)')
    doublon = Prestation.new(organisation: @org, code: 'DUP', libellé: 'y', tarif: 6, unité: 'Heure(s)')

    assert_not doublon.valid?
  end

  test 'unicité du code : même code dans une autre organisation → accepté' do
    Prestation.create!(organisation: @org, code: 'SHARED', libellé: 'x', tarif: 5, unité: 'Heure(s)')
    autre = Prestation.new(organisation: organisations(:mairie_marseille), code: 'SHARED', libellé: 'y', tarif: 6,
                           unité: 'Heure(s)')

    assert autre.valid?
  end

  test 'normalisation du code : minuscules → majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'abc12', libellé: 'x', tarif: 5, unité: 'Heure(s)')

    assert_equal 'ABC12', prestation.code
  end

  test 'normalisation de la catégorie : minuscules → majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'CAT1', libellé: 'x', tarif: 5, unité: 'Heure(s)',
                                    catégorie: 'entretien')

    assert_equal 'ENTRETIEN', prestation.catégorie
  end

  test 'normalisation de la sous-catégorie : minuscules → majuscules' do
    prestation = Prestation.create!(organisation: @org, code: 'CAT2', libellé: 'x', tarif: 5, unité: 'Heure(s)',
                                    sous_catégorie: 'vitres')

    assert_equal 'VITRES', prestation.sous_catégorie
  end

  test 'normalisation de l\'unité : espaces autour de la valeur → détourée' do
    prestation = Prestation.create!(organisation: @org, code: 'UNI1', libellé: 'x', tarif: 5, unité: '  heure  ')

    assert_equal 'heure', prestation.unité
  end

  test 'normalisation de l\'unité : valeur vide → nil' do
    prestation = Prestation.new(organisation: @org, code: 'UNI2', libellé: 'x', tarif: 5, unité: '   ')

    assert_nil prestation.unité
  end

  test 'scope ordered : plusieurs prestations → triées par code' do
    codes = Prestation.where(organisation: @org).ordered.pluck(:code)

    assert_equal codes.sort, codes
  end

  test 'display_name : code, libellé et tarif → une seule ligne lisible' do
    prestation = Prestation.new(code: 'NET01', libellé: 'Nettoyage', tarif: 25.5)

    assert_equal 'NET01 → Nettoyage (25.5 € HT)', prestation.display_name
  end
end
