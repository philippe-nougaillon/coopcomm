# frozen_string_literal: true

require 'test_helper'

class DashboardActiviteAgentsTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.current.change(hour: 12)
    [[users(:martin_technique_paris), 6, 15], [users(:bond), 3, 16]].each do |agent, temps, jour|
      intervention = Intervention.create!(adherent: users(:weil), service: services(:technique), description: "Intervention de #{agent.nom}",
                                          début: Time.zone.local(2023, 1, jour, 9), workflow_state: Intervention::VALIDE)
      intervention.update_columns(temps_total: temps)
      AgentIntervention.create!(agent: agent, intervention: intervention)
    end
    refresh_dashboard_views!
    sign_in users(:hidalgo)
  end

  test "En tant que manager, je veux trier l'activité de mes agents par une colonne et retomber sur le tableau" do
    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    tri = dashboard_path(du: '2023-01-01', au: '2023-01-31', column: 'agents.temps', direction: 'asc', anchor: 'activite-agents')
    assert_dom '#activite-agents a[href=?]', tri, text: /Temps/

    get tri

    assert_response :success
    agents = assigns(:activite_agents)[:lignes].map { |ligne| ligne[:agent] }
    assert_operator agents.index(users(:bond)), :<, agents.index(users(:martin_technique_paris))
  end

  test "En tant que manager, je veux que les filtres de l'activité des agents conservent le tri choisi" do
    get dashboard_url(du: '2023-01-01', au: '2023-01-31', column: 'agents.nom', direction: 'asc')

    assert_dom '#activite-agents form[action=?]', dashboard_path(anchor: 'activite-agents') do
      assert_dom 'input[type=hidden][name=column][value=?]', 'agents.nom'
      assert_dom 'input[type=hidden][name=direction][value=asc]'
      assert_dom 'input[type=hidden][name=du][value=?]', '2023-01-01'
    end
  end
end
