# frozen_string_literal: true

# Rafraîchit les vues matérialisées du dashboard, en synchrone. Si la volumétrie
# augmente, revenir au job coalescé RefreshDashboardViewsJob.
module DashboardRefreshable
  extend ActiveSupport::Concern

  VIEWS = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  # Colonnes d'Intervention qui influent sur les graphiques du dashboard.
  DASHBOARD_COLUMNS = %w[workflow_state temps_total co2 service_id adherent_id début].freeze

  # concurrently: false — seule variante permise dans une transaction (tests).
  def self.refresh_views!
    VIEWS.each do |view|
      Scenic.database.refresh_materialized_view(view, concurrently: false, cascade: false)
    end
  end

  def refresh_dashboard_views
    DashboardRefreshable.refresh_views!

    # Version complexifié qui permettrait de regrouper les refresh, s'il y en a trop
    # RefreshDashboardViewsJob.request_refresh
  end

  private

  def dashboard_relevant_change?
    saved_changes.keys.intersect?(DASHBOARD_COLUMNS)
  end
end
