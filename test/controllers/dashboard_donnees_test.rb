# frozen_string_literal: true

require 'test_helper'

class DashboardDonneesTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.current.change(hour: 12)
  end

  test 'dashboard : kpi_temps_total → somme des temps du périmètre du manager' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal '17.0h', assigns(:kpi_temps_total)
  end

  test 'dashboard : temps_total_par_service → temps cumulé par service' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_in_delta 17.0, assigns(:temps_total_par_service)['Technique']
  end

  test 'dashboard : temps_total_par_agent → temps réparti par agent' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: mois(3), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_in_delta 6.0, assigns(:temps_total_par_agent)['Martin Michel']
  end

  test 'dashboard : temps_total_par_adherent → temps cumulé par adhérent' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_in_delta 17.0, assigns(:temps_total_par_adherent)['Weil Ariel']
  end

  test 'dashboard : un adhérent reçoit le temps consommé et le temps restant de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url

    assert_in_delta 6.0, assigns(:proportion_temps_consomme)['temps_consomme']
    assert_in_delta 94.0, assigns(:proportion_temps_consomme)['temps_restant']
  end

  test 'dashboard : kpi_temps_total d’un adhérent → temps de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url

    assert_equal '6.0h', assigns(:kpi_temps_total)
  end

  test 'dashboard : temps_total_par_service d’un adhérent → temps de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url

    assert_in_delta 6.0, assigns(:temps_total_par_service)['Informatique']
  end

  test 'dashboard : temps_total_par_mois d’un adhérent → 0 sur un mois sans intervention' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url

    data = assigns(:temps_total_par_mois)
    assert_in_delta 6.0, data[mois(2).strftime('%Y-%m')]
    assert_in_delta 0.0, data[mois(1).strftime('%Y-%m')]
  end

  private

  def cree_intervention_avec_temps(temps, adherent:, service:, debut:, agent: nil)
    intervention = Intervention.create!(
      adherent: adherent,
      service: service,
      description: "Intervention de #{temps} h",
      début: debut,
      workflow_state: Intervention::VALIDE
    )
    intervention.update_columns(temps_total: temps)
    AgentIntervention.create!(agent: agent, intervention: intervention) if agent
    intervention
  end

  def mois(n)
    n.months.ago.beginning_of_month.change(hour: 9) + 14.days
  end

  def cree_donnees_adherent_informatique
    cree_intervention_avec_temps(6, adherent: users(:adhérent_sans_intervention),
                                    service: services(:informatique), debut: mois(2))
    refresh_dashboard_views!
  end
end
