# frozen_string_literal: true

require 'test_helper'

class ConventionsHelperTest < ActionView::TestCase
  setup do
    travel_to Time.zone.local(2026, 7, 1, 12)
  end

  test 'une convention à venir est annoncée à 0 % avec la couleur info' do
    prog = convention_progress(convention(Date.new(2026, 7, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 6, 1))
    assert_equal 0, prog[:percent]
    assert_equal 'À venir', prog[:label]
    assert_equal 'progress-info', prog[:color]
  end

  test 'une convention à mi-parcours est à 50 % environ avec la couleur success' do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 7, 1))
    assert_in_delta 50, prog[:percent], 1
    assert_equal 'progress-success', prog[:color]
    refute prog[:indeterminate]
  end

  test "une convention consommée en avance de 10 % sur le rythme de l'année passe en couleur warning" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), nil, conventionnees: 365, consommees: 110),
                               today: Date.new(2026, 4, 10))
    assert_equal 'progress-warning', prog[:color]
  end

  test 'une convention expirée est annoncée à 100 % avec la couleur error' do
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

  test "une convention sans date de fin avance avec l'année en cours" do
    prog = convention_progress(convention(Date.new(2024, 3, 1), nil), today: Date.new(2026, 7, 1))
    assert_equal 50, prog[:percent]
    assert_equal 'progress-success', prog[:color]
  end

  test "une convention commencée en cours d'année avance sur la part de l'année qu'elle couvre" do
    prog = convention_progress(convention(Date.new(2026, 7, 1), nil), today: Date.new(2026, 10, 1))
    assert_equal 50, prog[:percent]
  end

  test 'une convention expirée une année précédente est annoncée à 100 % avec la couleur error' do
    prog = convention_progress(convention(Date.new(2024, 1, 1), Date.new(2024, 12, 31)),
                               today: Date.new(2026, 7, 1))
    assert_equal 100, prog[:percent]
    assert_equal 'Expirée', prog[:label]
    assert_equal 'progress-error', prog[:color]
  end

  test 'une convention qui commence une année suivante reste annoncée à venir le 31 décembre' do
    prog = convention_progress(convention(Date.new(2027, 3, 1), nil), today: Date.new(2026, 12, 31))
    assert_equal 0, prog[:percent]
    assert_equal 'À venir', prog[:label]
  end

  test "une convention consommée en avance de moins de 10 % sur le rythme de l'année reste en couleur success" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), nil, conventionnees: 365, consommees: 109),
                               today: Date.new(2026, 4, 10))
    assert_equal 'progress-success', prog[:color]
  end

  test 'une convention dont les heures conventionnées sont dépassées passe en couleur error' do
    assert_equal 'progress-error', heures(conventionnees: 10, consommees: 15)[:color]
  end

  test 'une convention dont les heures consommées égalent les heures conventionnées ne passe pas en couleur error' do
    assert_equal 'progress-warning', heures(conventionnees: 10, consommees: 10)[:color]
  end

  # ==================== Indicateur d'heures consommées ====================

  test 'une convention sans heures conventionnées a un indicateur à zéro, sans division par zéro' do
    prog = heures(conventionnees: nil, consommees: 12)

    assert_equal 0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
  end

  test 'des heures conventionnées à zéro donnent un indicateur à zéro' do
    assert_equal 0, heures(conventionnees: 0, consommees: 12)[:indicateur]
  end

  test 'une consommation en deçà du contrat donne un indicateur proportionnel en couleur neutre' do
    prog = heures(conventionnees: 10, consommees: 5)

    assert_equal 50.0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
    assert_equal 0, prog[:depassement]
    assert_match 'Temps écoulé', prog[:indicateur_label]
  end

  test 'une consommation exactement au contrat reste en couleur neutre' do
    prog = heures(conventionnees: 10, consommees: 10)

    assert_equal 100.0, prog[:indicateur]
    assert_equal 'bg-neutral', prog[:indicateur_color]
  end

  test "un dépassement du contrat plafonne l'indicateur, passe en couleur d'alerte et annonce l'écart" do
    prog = heures(conventionnees: 10, consommees: 15)

    assert_equal 100, prog[:indicateur]
    assert_equal 'bg-error', prog[:indicateur_color]
    assert_equal 5, prog[:depassement]
    assert_match 'Durée dépassée de 5.0h', prog[:indicateur_label]
  end

  test "une consommation négative met l'indicateur à zéro et invite à corriger les interventions" do
    prog = heures(conventionnees: 10, consommees: -3)

    assert_equal 0, prog[:indicateur]
    assert_equal 'bg-error', prog[:indicateur_color]
    assert_match 'temps total positif', prog[:indicateur_label]
  end

  private

  def convention(start_date, end_date, conventionnees: nil, consommees: nil)
    convention = Convention.new(user: users(:patrick_adherent_paris), service: services(:service_paris),
                                date_début: start_date, date_fin_prévue: end_date,
                                heures_conventionnees: conventionnees)
    poser_heures_consommees(convention, consommees) if consommees
    convention
  end

  def poser_heures_consommees(convention, heures)
    Intervention.create!(description: 'Intervention sous convention',
                         adherent_id: convention.user_id, service_id: convention.service_id,
                         début: convention.date_début.beginning_of_day + 9.hours,
                         slug: SecureRandom.uuid)
                .update_columns(temps_total: heures)
  end

  def heures(conventionnees:, consommees:)
    convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31),
                                   conventionnees: conventionnees, consommees: consommees),
                        today: Date.new(2026, 7, 1))
  end
end
