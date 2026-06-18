# frozen_string_literal: true

class UpdateDashboardAgentStatsToVersion2 < ActiveRecord::Migration[8.0]
  # Scenic réapplique automatiquement les index existants lors d'un update_view
  # matérialisé (IndexReapplication) : inutile — et incorrect — de recréer
  # idx_dashboard_agent_stats_unique à la main, il survit à la mise à jour.
  # update_view est réversible grâce à revert_to_version.
  def change
    update_view :dashboard_agent_stats, version: 2, revert_to_version: 1, materialized: true
  end
end
