# frozen_string_literal: true

class UpdateDashboardViewsToPlannedStart < ActiveRecord::Migration[8.1]
  def change
    update_view :dashboard_intervention_stats, version: 2, revert_to_version: 1, materialized: true
    update_view :dashboard_agent_stats, version: 5, revert_to_version: 4, materialized: true
  end
end
