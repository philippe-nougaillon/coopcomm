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

  test 'un bloc regroupé ne rafraîchit les vues qu’une seule fois, à sa fin' do
    base = Minitest::Mock.new
    ActualiserDashboard::VUES.each { |vue| base.expect(:refresh_materialized_view, nil, [vue], concurrently: true) }

    Scenic.stub(:database, base) do
      ActualiserDashboard.regrouper do
        3.times { ActualiserDashboard.call }
        assert_raises(MockExpectationError) { base.verify }
      end
    end

    assert_mock base
  end

  test 'un bloc regroupé imbriqué dans un autre ne rafraîchit les vues qu’à la fin du bloc extérieur' do
    base = Minitest::Mock.new
    ActualiserDashboard::VUES.each { |vue| base.expect(:refresh_materialized_view, nil, [vue], concurrently: true) }

    Scenic.stub(:database, base) do
      ActualiserDashboard.regrouper do
        ActualiserDashboard.regrouper { ActualiserDashboard.call }
        assert_raises(MockExpectationError) { base.verify }
      end
    end

    assert_mock base
  end

  test 'un bloc regroupé interrompu par une erreur rafraîchit quand même les vues' do
    base = Minitest::Mock.new
    ActualiserDashboard::VUES.each { |vue| base.expect(:refresh_materialized_view, nil, [vue], concurrently: true) }

    Scenic.stub(:database, base) do
      assert_raises(RuntimeError) { ActualiserDashboard.regrouper { raise 'interrompu' } }
    end

    assert_mock base
  end

  test 'après un bloc regroupé, chaque appel rafraîchit de nouveau les vues' do
    base = Minitest::Mock.new
    2.times { ActualiserDashboard::VUES.each { |vue| base.expect(:refresh_materialized_view, nil, [vue], concurrently: true) } }

    Scenic.stub(:database, base) do
      ActualiserDashboard.regrouper { nil }
      ActualiserDashboard.call
    end

    assert_mock base
  end
end
