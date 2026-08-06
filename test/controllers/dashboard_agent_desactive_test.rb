# frozen_string_literal: true

require 'test_helper'

# Un agent désactivé garde son temps au dashboard, mais pas son nom : sa part est
# cumulée sous « Utilisateur désactivé ».
class DashboardAgentDesactiveTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.current.change(hour: 12)
    @desactive = users_with_discarded(:agent_discarded_paris)
    refresh_dashboard_views!
    sign_in users(:hidalgo)
  end

  def users_with_discarded(nom)
    User.with_discarded.find(ActiveRecord::FixtureSet.identify(nom))
  end

  test 'le nom d’un agent désactivé n’apparaît pas dans le graphique' do
    get dashboard_url

    assert_not_includes assigns(:temps_total_par_agent).keys, @desactive.nom_prénom
  end

  test 'son temps est conservé sous « Utilisateur désactivé »' do
    tonte = interventions(:tonte_locaux)
    part = tonte.temps_total / AgentIntervention.where(intervention_id: tonte.id).count

    get dashboard_url
    par_agent = assigns(:temps_total_par_agent)

    assert_includes par_agent.keys, DashboardData::LIBELLE_AGENT_DESACTIVE
    assert_in_delta part, par_agent[DashboardData::LIBELLE_AGENT_DESACTIVE], 0.01
  end

  test 'deux agents désactivés ont chacun leur entrée, la seconde numérotée' do
    bond = users(:bond)
    nom_bond = bond.nom_prénom
    bond.discard
    refresh_dashboard_views!

    get dashboard_url
    par_agent = assigns(:temps_total_par_agent)
    libellé = DashboardData::LIBELLE_AGENT_DESACTIVE

    assert_includes par_agent.keys, libellé
    assert_includes par_agent.keys, "#{libellé} #2"
    assert_not_includes par_agent.keys, nom_bond
    assert_not_includes par_agent.keys, @desactive.nom_prénom
  end

  test 'aucune entrée « Utilisateur désactivé » quand aucun agent désactivé n’a de temps' do
    AgentIntervention.where(agent_id: @desactive.id).destroy_all

    get dashboard_url

    assert_not_includes assigns(:temps_total_par_agent).keys, DashboardData::LIBELLE_AGENT_DESACTIVE
  end

  test 'le temps des agents actifs reste inchangé' do
    tonte = interventions(:tonte_locaux)
    part = tonte.temps_total / AgentIntervention.where(intervention_id: tonte.id).count

    get dashboard_url

    assert_in_delta part, assigns(:temps_total_par_agent)[users(:bond).nom_prénom], 0.01
  end
end
