# frozen_string_literal: true

class UpdateDashboardAgentStatsToVersion4 < ActiveRecord::Migration[8.1]
  # L'index unique change de colonnes : retiré avant l'update_view (Scenic
  # réappliquerait l'ancien), recréé sur le nouveau grain après.
  def change
    remove_index :dashboard_agent_stats, %i[organisation_id agent_id],
                 unique: true, name: 'idx_dashboard_agent_stats_unique'
    update_view :dashboard_agent_stats, version: 4, revert_to_version: 3, materialized: true
    add_index :dashboard_agent_stats, %i[organisation_id service_id agent_id mois],
              unique: true, name: 'idx_dashboard_agent_stats_unique'
  end
end
