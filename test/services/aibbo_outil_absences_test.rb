# frozen_string_literal: true

require 'test_helper'

class AibboOutilAbsencesTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Une absence et son motif sont des informations personnelles : elles ne sortent pas des comptes
  # dont l'utilisateur peut ouvrir la fiche.
  test 'un manager reçoit les absences des comptes de ses services (critique)' do
    resultat = Aibbo::OutilAbsences.new(@manager).call

    assert_equal [absences(:one).du, absences(:two).du], resultat[:absences].pluck('du')
    assert_equal [users(:bond).nom_prénom.strip], resultat[:absences].pluck('personne').uniq
  end

  test 'un manager ne reçoit aucune absence d’un compte hors de ses services (critique)' do
    resultat = Aibbo::OutilAbsences.new(users(:manager_marseille)).call

    assert_empty resultat[:absences]
    assert_equal 0, resultat[:total]
  end

  test 'le nom d’une personne hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilAbsences.new(users(:manager_marseille)).call(personne: 'bond')

    assert_match(/introuvable parmi les personnes/, resultat[:erreur])
    assert_nil resultat[:absences]
  end

  test 'un agent ne reçoit les absences d’aucun autre compte (critique)' do
    assert_empty Aibbo::OutilAbsences.new(users(:martin_technique_paris)).call[:absences]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la période ne garde que les absences qui la touchent' do
    resultat = Aibbo::OutilAbsences.new(@manager).call(du: '2024-11-21', au: '2024-11-30')

    assert_equal [absences(:two).du], resultat[:absences].pluck('du')
    assert_equal 1, resultat[:total]
  end

  test 'le filtre par personne retrouve un prénom écrit sans majuscule' do
    resultat = Aibbo::OutilAbsences.new(@manager).call(personne: 'james')

    assert_equal [absences(:one).du, absences(:two).du], resultat[:absences].pluck('du')
  end

  test 'une absence d’une journée entière compte un jour' do
    absence = Aibbo::OutilAbsences.new(@manager).call(du: '2024-11-20', au: '2024-11-20')[:absences].first

    assert_equal 1, absence['jours']
    assert_equal 'Journée entière', absence['période']
  end

  test 'un agent reçoit ses propres absences' do
    resultat = Aibbo::OutilAbsences.new(users(:bond)).call

    assert_equal [absences(:one).du, absences(:two).du], resultat[:absences].pluck('du')
    assert_equal [users(:bond).nom_prénom.strip], resultat[:absences].pluck('personne').uniq
  end
end
