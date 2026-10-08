# frozen_string_literal: true

class DropDashboardRefreshTriggers < ActiveRecord::Migration[8.1]
  def up
    execute 'DROP TRIGGER IF EXISTS interventions_refresh_dashboard ON interventions;'
    execute 'DROP TRIGGER IF EXISTS agent_interventions_refresh_dashboard ON agent_interventions;'
    execute 'DROP FUNCTION IF EXISTS refresh_dashboard_views();'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
