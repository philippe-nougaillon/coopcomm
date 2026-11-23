# frozen_string_literal: true

require 'test_helper'

class AibboOutilConventionsTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Les conventions suivent la visibilité de leur liste (services du manager, organisation de l'administrateur,
  # les siennes pour l'adhérent), et leurs heures sont de l'argent conventionné.
  test 'un manager reçoit les conventions de ses services (critique)' do
    assert_equal [['Weil Ariel', 'Informatique']], adherents_et_services(Aibbo::OutilConventions.new(@manager).call)
  end

  test 'un administrateur ne reçoit que les conventions de son organisation (critique)' do
    assert_equal [['Weil Ariel', 'Informatique'], %w[Lucas Comptabilité]],
                 adherents_et_services(Aibbo::OutilConventions.new(users(:administrateur_paris)).call)
  end

  test 'un adhérent reçoit ses propres conventions (critique)' do
    assert_equal [['Weil Ariel', 'Informatique']], adherents_et_services(Aibbo::OutilConventions.new(users(:weil)).call)
  end

  test 'un adhérent ne reçoit pas les conventions des autres adhérents (critique)' do
    resultat = Aibbo::OutilConventions.new(users(:berthout)).call

    assert_empty resultat[:conventions]
    assert_equal 0, resultat[:total]
  end

  test 'le nom d’un adhérent hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilConventions.new(@manager).call(adherent: 'Jackson')

    assert_match(/introuvable parmi les adhérents/, resultat[:erreur])
    assert_nil resultat[:conventions]
  end

  test 'les heures consommées et planifiées d’une convention sont celles des interventions de son adhérent et de son service (critique)' do
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Dépannage fait',
                         début: Time.zone.local(2026, 3, 10, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 4)
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Dépannage prévu',
                         début_prévue: Time.zone.local(2026, 11, 10, 9), fin_prévue: Time.zone.local(2026, 11, 10, 11),
                         workflow_state: Intervention::NOUVEAU)
    Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Tonte hors convention',
                         début: Time.zone.local(2026, 3, 11, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 9)

    resultat = travel_to(Time.zone.local(2026, 10, 26, 12)) { Aibbo::OutilConventions.new(@manager).call }
    convention = resultat[:conventions].first

    assert_equal [100.0, 4.0, 2.0, 96.0, 4], convention.values_at(:heures_conventionnées, :heures_consommées, :heures_planifiées,
                                                                  :heures_restantes, :taux_de_consommation)
    assert_equal [100.0, 4.0, 2.0], resultat.values_at(:heures_conventionnées, :heures_consommées, :heures_planifiées)
  end

  test 'une convention dont les heures consommées dépassent les heures conventionnées porte son dépassement et passe le filtre des dépassées (critique)' do
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Migration des postes',
                         début: Time.zone.local(2026, 5, 4, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 120)

    convention = travel_to(Time.zone.local(2026, 10, 26, 12)) { Aibbo::OutilConventions.new(@manager).call(depassees: true)[:conventions].sole }

    assert_equal ['Weil Ariel', 20.0, 120], convention.values_at(:adhérent, :dépassement, :taux_de_consommation)
    assert_not convention.key?(:heures_restantes)
  end

  test 'le filtre des dépassées écarte une convention restée sous ses heures conventionnées (critique)' do
    assert_empty Aibbo::OutilConventions.new(@manager).call(depassees: true)[:conventions]
  end

  test 'les heures d’une convention sans date de fin sont celles de l’année civile en cours, rendue avec elles (critique)' do
    Intervention.create!(adherent: users(:george_lucas), service: services(:comptabilite), description: 'Bilan fait l’an passé',
                         début: Time.zone.local(2025, 11, 12, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 7)
    Intervention.create!(adherent: users(:george_lucas), service: services(:comptabilite), description: 'Bilan fait cette année',
                         début: Time.zone.local(2026, 3, 10, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 4)

    convention = travel_to(Time.zone.local(2026, 10, 26, 12)) { Aibbo::OutilConventions.new(users(:george_lucas)).call[:conventions].sole }

    assert_equal [2026, 4.0, 196.0], convention.values_at(:année_des_heures, :heures_consommées, :heures_restantes)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le filtre par service ne garde que les conventions de ce service' do
    assert_equal [['Weil Ariel', 'Informatique']], adherents_et_services(Aibbo::OutilConventions.new(@manager).call(service: 'informatique'))
    assert_empty Aibbo::OutilConventions.new(@manager).call(service: 'Technique')[:conventions]
  end

  test 'la période garde une convention qui la recouvre en partie, et écarte celle qui ne la touche pas' do
    assert_equal [['Weil Ariel', 'Informatique']],
                 adherents_et_services(Aibbo::OutilConventions.new(@manager).call(du: '2026-12-15', au: '2027-01-15'))
    assert_empty Aibbo::OutilConventions.new(@manager).call(du: '2027-01-01')[:conventions]
  end

  test 'la période garde une convention sans date de fin qui a commencé avant elle' do
    assert_equal [%w[Lucas Comptabilité]], adherents_et_services(Aibbo::OutilConventions.new(users(:george_lucas)).call(du: '2027-01-01'))
  end

  test 'une convention sans date de fin est rendue sans fin de période' do
    convention = Aibbo::OutilConventions.new(users(:george_lucas)).call[:conventions].sole

    assert_equal ['2025-01-01', nil], convention.values_at(:du, :au)
  end

  private

  # Adhérent et service de chaque convention rendue, dans l'ordre du résultat.
  def adherents_et_services(resultat)
    resultat[:conventions].map { |convention| convention.values_at(:adhérent, :service) }
  end
end
