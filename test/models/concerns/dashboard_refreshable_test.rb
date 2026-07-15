# frozen_string_literal: true

require 'test_helper'

# Vérifie le câblage du rafraîchissement des vues : callbacks after_commit posés,
# détection des seules modifications pertinentes, et refresh synchrone effectif
# (depuis le 2026-07-15 le refresh est direct, sans passer par un job).
class DashboardRefreshableTest < ActiveSupport::TestCase
  test 'Intervention et AgentIntervention incluent le concern' do
    assert Intervention.include?(DashboardRefreshable)
    assert AgentIntervention.include?(DashboardRefreshable)
  end

  test 'callback after_commit enregistré sur Intervention' do
    filters = Intervention._commit_callbacks.map(&:filter)
    assert_includes filters, :refresh_dashboard_views
  end

  test 'callback after_commit enregistré sur AgentIntervention' do
    filters = AgentIntervention._commit_callbacks.map(&:filter)
    assert_includes filters, :refresh_dashboard_views
  end

  test 'dashboard_relevant_change? vrai quand une colonne du dashboard change' do
    iv = Intervention.new
    iv.stub(:saved_changes, { 'workflow_state' => %w[nouveau terminé] }) do
      assert iv.send(:dashboard_relevant_change?)
    end
  end

  test 'dashboard_relevant_change? faux pour une colonne hors dashboard' do
    iv = Intervention.new
    iv.stub(:saved_changes, { 'description' => %w[a b] }) do
      assert_not iv.send(:dashboard_relevant_change?)
    end
  end

  test 'refresh_dashboard_views rafraîchit les deux vues matérialisées' do
    refreshed = []
    stub = ->(view, **) { refreshed << view }
    Scenic.database.stub(:refresh_materialized_view, stub) do
      Intervention.new.refresh_dashboard_views
    end
    assert_equal DashboardRefreshable::VIEWS, refreshed
  end

  test "un changement d'état est répercuté dans la vue sans autre action" do
    iv = interventions(:tonte_locaux)
    refresh_dashboard_views!

    assert_difference -> { DashboardInterventionStat.where(workflow_state: 'archivé').sum(:nb) }, +1 do
      iv.update!(workflow_state: 'archivé')
    end
  end
end
