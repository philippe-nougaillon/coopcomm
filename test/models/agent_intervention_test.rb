# frozen_string_literal: true

require 'test_helper'

class AgentInterventionTest < ActiveSupport::TestCase
  setup do
    @intervention = interventions(:tonte_locaux)
    refresh_dashboard_views!
  end

  test 'un agent affecté reçoit sa part du temps dans les statistiques du tableau de bord' do
    agent = users(:john_wick)

    AgentIntervention.create!(agent: agent, intervention: @intervention)

    assert_operator DashboardAgentStat.where(agent_id: agent.id).sum(:temps_total), :>, 0
  end

  test 'un agent retiré perd sa part du temps dans les statistiques du tableau de bord' do
    bond = users(:bond)
    part = @intervention.temps_total / AgentIntervention.where(intervention_id: @intervention.id).count
    avant = DashboardAgentStat.where(agent_id: bond.id).sum(:temps_total).to_f

    @intervention.agent_interventions.find_by(agent: bond).destroy!

    assert_in_delta avant - part, DashboardAgentStat.where(agent_id: bond.id).sum(:temps_total).to_f, 0.01
  end
end
