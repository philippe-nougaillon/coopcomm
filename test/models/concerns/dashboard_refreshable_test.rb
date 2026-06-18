# frozen_string_literal: true

require 'test_helper'

# Vérifie le câblage du rafraîchissement des vues : callbacks after_commit posés,
# détection des seules modifications pertinentes, et planification du job.
class DashboardRefreshableTest < ActiveJob::TestCase
  test 'Intervention et AgentIntervention incluent le concern' do
    assert Intervention.include?(DashboardRefreshable)
    assert AgentIntervention.include?(DashboardRefreshable)
  end

  test 'callback after_commit enregistré sur Intervention' do
    filters = Intervention._commit_callbacks.map(&:filter)
    assert_includes filters, :enqueue_dashboard_refresh
  end

  test 'callback after_commit enregistré sur AgentIntervention' do
    filters = AgentIntervention._commit_callbacks.map(&:filter)
    assert_includes filters, :enqueue_dashboard_refresh
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

  test 'enqueue_dashboard_refresh planifie le job de refresh' do
    assert_enqueued_with(job: RefreshDashboardViewsJob) do
      Intervention.new.send(:enqueue_dashboard_refresh)
    end
  end
end
