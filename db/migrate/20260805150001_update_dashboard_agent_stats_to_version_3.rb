# frozen_string_literal: true

class UpdateDashboardAgentStatsToVersion3 < ActiveRecord::Migration[8.0]
  # Scenic réapplique seul les index d'une vue matérialisée lors d'un update_view :
  # ne pas recréer idx_dashboard_agent_stats_unique à la main.
  def change
    update_view :dashboard_agent_stats, version: 3, revert_to_version: 2, materialized: true
  end
end
