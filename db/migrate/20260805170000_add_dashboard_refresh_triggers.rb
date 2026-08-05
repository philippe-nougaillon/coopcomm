# frozen_string_literal: true

class AddDashboardRefreshTriggers < ActiveRecord::Migration[8.0]
  def change
    create_function :refresh_dashboard_views
    create_trigger :interventions_refresh_dashboard, on: :interventions
    create_trigger :agent_interventions_refresh_dashboard, on: :agent_interventions
  end
end
