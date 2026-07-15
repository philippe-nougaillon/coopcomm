# frozen_string_literal: true

require 'test_helper'

# Couverture du filtre #292 : « les interventions avec un temps négatif ne sont
# plus prises en compte lors des calculs de temps ». Sur cette branche, le
# filtre (`temps_total >= 0`) est appliqué dans DashboardData PAR-DESSUS les
# vues matérialisées — donc au grain des CELLULES pré-agrégées, pas au grain
# intervention comme le #292 d'origine (staging). Les écarts sont épinglés
# ci-dessous (B13, cf. .claude/method/bugs-signales.md) ; l'oubli de
# temps_par_adherent (ex-B12) est corrigé sur cette branche depuis le 2026-07-13.
#
# Repères fixtures : dans le périmètre de hidalgo (manager Paris), seule
# tonte_locaux porte du temps (9 h, adhérent weil, agent bond — le co-agent
# discarded ne compte pas dans le diviseur) ; toutes les autres interventions
# sont au défaut de colonne (0.0).
class DashboardTempsNegatifTest < ActionDispatch::IntegrationTest
  setup do
    # Ancrage à midi : pas de dérive d'heure/de mois pendant le test (cf. B10).
    travel_to Time.current.change(hour: 12)
  end

  # ---------------------------------------------------------------------------
  # Dashboard manager (hidalgo — services technique/informatique/service_paris)
  # ---------------------------------------------------------------------------

  test 'manager : kpi_temps_total ignore une intervention à temps négatif' do
    cree_intervention_avec_temps(-5, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    # 9 h de tonte_locaux uniquement — sans le filtre, le -5 donnerait "4.0h".
    assert_equal '9.0h', assigns(:kpi_temps_total)
  end

  test 'manager : temps_total_par_service ignore une intervention à temps négatif' do
    cree_intervention_avec_temps(-5, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_in_delta 9.0, assigns(:temps_total_par_service)['Technique']
  end

  test 'manager : un agent dont le temps net est négatif est affiché à 0, jamais en négatif' do
    martin = users(:martin_technique_paris)
    cree_intervention_avec_temps(-3, adherent: users(:weil), service: services(:technique),
                                     debut: mois(3), agent: martin)
    refresh_dashboard_views!
    # Sanity : la vue porte bien le total négatif — c'est le filtre du concern
    # (temps_par_agent) qui doit le neutraliser, pas la vue.
    assert_in_delta(-3.0, DashboardAgentStat.where(agent_id: martin.id).sum(:temps_total))
    sign_in users(:hidalgo)

    get dashboard_url

    assert_in_delta 0.0, assigns(:temps_total_par_agent)['Martin Michel']
  end

  test "manager : ÉPINGLAGE B13 — le filtre agent opère sur le NET de l'agent, pas par intervention" do
    # bond porte déjà +9 h (tonte_locaux) ; on lui impute -5 h.
    cree_intervention_avec_temps(-5, adherent: users(:weil), service: services(:technique),
                                     debut: mois(3), agent: users(:bond))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    # Comportement ACTUEL (approximation au grain agent, actée le 2026-07-13) :
    # 9 - 5 = 4. Le #292 strict (grain intervention, comme staging) afficherait 9.
    # À inverser si la décision B13 retient le grain intervention.
    assert_in_delta 4.0, assigns(:temps_total_par_agent)['Bond James']
  end

  test "manager : ÉPINGLAGE B13 — un négatif est absorbé par une cellule positive du même mois" do
    # Même cellule de la vue (org, service, adhérent, mois, statut) : +8 et -3
    # s'agrègent en 5 >= 0 → la cellule passe le filtre et le -3 est COMPTÉ.
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    cree_intervention_avec_temps(-3, adherent: users(:weil), service: services(:technique),
                                     debut: mois(3) + 1.day)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    # Comportement ACTUEL : 9 (tonte) + (8 - 3) = 14. Le #292 strict donnerait "17.0h".
    # À inverser si la décision B13 retient le grain intervention.
    assert_equal '14.0h', assigns(:kpi_temps_total)
  end

  test 'manager : temps_total_par_adherent exclut le temps négatif (ex-B12, corrigé 2026-07-13)' do
    cree_intervention_avec_temps(-5, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    # weil porte 9 h (tonte_locaux) ; le -5 ne doit pas les entamer.
    assert_in_delta 9.0, assigns(:temps_total_par_adherent)['Weil Ariel']
  end

  # ---------------------------------------------------------------------------
  # Dashboard adhérent (weil — son dashboard est scopé sur SON service,
  # informatique : ses interventions de fixtures, toutes sur technique, n'y
  # apparaissent pas ; seules celles créées ici comptent)
  # ---------------------------------------------------------------------------

  test 'adhérent : le temps consommé exclut une intervention à temps négatif' do
    cree_donnees_adherent_weil
    sign_in users(:weil)

    get dashboard_url

    # +6 seulement — sans le filtre, le -4 donnerait 2 consommé / 98 restant.
    assert_in_delta 6.0, assigns(:proportion_temps_consomme)['temps_consomme']
    assert_in_delta 94.0, assigns(:proportion_temps_consomme)['temps_restant']
  end

  test 'adhérent : kpi_temps_total exclut une intervention à temps négatif' do
    cree_donnees_adherent_weil
    sign_in users(:weil)

    get dashboard_url

    assert_equal '6.0h', assigns(:kpi_temps_total)
  end

  test 'adhérent : temps_total_par_service exclut une intervention à temps négatif' do
    cree_donnees_adherent_weil
    sign_in users(:weil)

    get dashboard_url

    assert_in_delta 6.0, assigns(:temps_total_par_service)['Informatique']
  end

  test 'adhérent : le mois qui ne porte qu-un temps négatif reste à 0 dans temps_total_par_mois' do
    cree_donnees_adherent_weil
    sign_in users(:weil)

    get dashboard_url

    data = assigns(:temps_total_par_mois)
    assert_in_delta 6.0, data[mois(2).strftime('%Y-%m')]
    assert_in_delta 0.0, data[mois(1).strftime('%Y-%m')]
  end

  private

  # Crée une intervention persistée puis force temps_total via update_columns :
  # indépendant du before_save calc_temps_total (B1, inopérant aujourd'hui) et
  # robuste au jour où B1 sera corrigé (le callback recalculerait depuis début/fin).
  # L'agent est rattaché APRÈS la création : on teste le dashboard, pas les
  # contrôles de disponibilité (#357).
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

  # Le 15 du mois d'il y a n mois à 9 h : toujours passé (validation
  # dates_cannot_be_in_the_future) et chaque n tombe dans un mois distinct
  # (cellules de vue séparées).
  def mois(n)
    n.months.ago.beginning_of_month.change(hour: 9) + 14.days
  end

  # +6 h il y a 2 mois, -4 h le mois dernier, pour weil sur SON service
  # (informatique) — le seul visible depuis son dashboard adhérent.
  def cree_donnees_adherent_weil
    cree_intervention_avec_temps(6, adherent: users(:weil),
                                    service: services(:informatique), debut: mois(2))
    cree_intervention_avec_temps(-4, adherent: users(:weil),
                                     service: services(:informatique), debut: mois(1))
    refresh_dashboard_views!
  end
end
