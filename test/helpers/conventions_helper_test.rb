# frozen_string_literal: true

require 'test_helper'

class ConventionsHelperTest < ActionView::TestCase
  def convention(start_date, end_date, conventionnees: nil, consommees: nil)
    Convention.new(date_début: start_date, date_fin_prévue: end_date,
                   heures_conventionnees: conventionnees, heures_consommees: consommees)
  end

  def heures(conventionnees:, consommees:)
    convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31),
                                   conventionnees: conventionnees, consommees: consommees),
                        today: Date.new(2026, 7, 1))
  end

  

  test 'convention à venir : 0 % et couleur info' do
    prog = convention_progress(convention(Date.new(2026, 7, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 6, 1))
    assert_equal 0, prog[:percent]
    assert_equal 'À venir', prog[:label]
    assert_equal 'progress-info', prog[:color]
  end

  test 'convention à mi-parcours : ~50 % et couleur success' do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 7, 1))
    assert_in_delta 50, prog[:percent], 1
    assert_equal 'progress-success', prog[:color]
    refute prog[:indeterminate]
  end

  test "convention proche de l'échéance : couleur warning au-delà de 80 %" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 12, 1))
    assert_operator prog[:percent], :>=, 80
    assert_equal 'progress-warning', prog[:color]
  end

  test 'convention expirée : 100 % et couleur error' do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 6, 30)),
                               today: Date.new(2026, 8, 1))
    assert_equal 100, prog[:percent]
    assert_equal 'Expirée', prog[:label]
    assert_equal 'progress-error', prog[:color]
  end

  test 'début et fin le même jour ne lève pas de division par zéro' do
    same = Date.new(2026, 6, 8)
    assert_equal 100, convention_progress(convention(same, same), today: same)[:percent]
    assert_equal 0,   convention_progress(convention(same, same), today: same - 1)[:percent]
  end

  # ==================== Indicateur d'heures consommées ====================

  test 'aucune heure conventionnée : indicateur à zéro, pas de division par zéro' do
    prog = heures(conventionnees: nil, consommees: 12)

    assert_equal 0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
  end

  test 'heures conventionnées à zéro : indicateur à zéro' do
    assert_equal 0, heures(conventionnees: 0, consommees: 12)[:indicateur]
  end

  test 'consommation en deçà du contrat : indicateur proportionnel et couleur neutre' do
    prog = heures(conventionnees: 10, consommees: 5)

    assert_equal 50.0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
    assert_equal 0, prog[:depassement]
    assert_match 'Temps écoulé', prog[:indicateur_label]
  end

  test 'consommation exactement au contrat : encore neutre' do
    prog = heures(conventionnees: 10, consommees: 10)

    assert_equal 100.0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
  end

  test 'dépassement du contrat : indicateur plafonné, couleur d\'alerte et écart annoncé' do
    prog = heures(conventionnees: 10, consommees: 15)

    assert_equal 100, prog[:indicateur]
    assert_equal 'bg-error', prog[:indicateur_color]
    assert_equal 5, prog[:depassement]
    assert_match 'Durée dépassée de 5.0h', prog[:indicateur_label]
  end

  test 'consommation négative : indicateur à zéro et invitation à corriger les interventions' do
    prog = heures(conventionnees: 10, consommees: -3)

    assert_equal 0, prog[:indicateur]
    assert_equal 'bg-error', prog[:indicateur_color]
    assert_match 'temps total positif', prog[:indicateur_label]
  end
end
