# frozen_string_literal: true

require 'test_helper'

class InterventionDashboardTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test 'une intervention créée est comptée dans les statistiques du tableau de bord' do
    assert_difference -> { DashboardInterventionStat.sum(:nb) }, +1 do
      Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Élagage',
                           workflow_state: Intervention::VALIDE, début: Time.zone.local(2024, 3, 4, 9))
    end
  end

  test 'un changement d’état est répercuté dans les statistiques du tableau de bord' do
    assert_difference -> { DashboardInterventionStat.where(workflow_state: Intervention::ARCHIVE).sum(:nb) }, +1 do
      interventions(:tonte_locaux).update!(workflow_state: Intervention::ARCHIVE)
    end
  end

  test 'une intervention supprimée disparaît des statistiques du tableau de bord' do
    intervention = Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Élagage',
                                        workflow_state: Intervention::VALIDE, début: Time.zone.local(2024, 3, 4, 9))

    assert_difference -> { DashboardInterventionStat.sum(:nb) }, -1 do
      intervention.destroy!
    end
  end
end
