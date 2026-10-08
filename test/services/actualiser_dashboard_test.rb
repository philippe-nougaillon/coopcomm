# frozen_string_literal: true

require 'test_helper'

class ActualiserDashboardTest < ActiveSupport::TestCase
  setup { ActualiserDashboard.call }

  test 'le temps modifié d’une intervention est répercuté dans les statistiques des interventions' do
    intervention = interventions(:tonte_locaux)
    attendu = DashboardInterventionStat.sum(:temps_total).to_f - intervention.temps_total + 7
    intervention.update_columns(temps_total: 7)

    ActualiserDashboard.call

    assert_in_delta attendu, DashboardInterventionStat.sum(:temps_total).to_f, 0.01
  end

  test 'une affectation retirée est répercutée dans les statistiques des agents' do
    intervention = interventions(:tonte_locaux)
    attendu = DashboardAgentStat.sum(:temps_total).to_f - intervention.temps_total
    AgentIntervention.where(intervention_id: intervention.id).delete_all

    ActualiserDashboard.call

    assert_in_delta attendu, DashboardAgentStat.sum(:temps_total).to_f, 0.01
  end
end
