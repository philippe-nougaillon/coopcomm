# frozen_string_literal: true

# Rafraîchit les vues matérialisées du dashboard quand une donnée qui les
# alimente change. Inclus dans Intervention et AgentIntervention.
#
# Refresh synchrone et basique, assumé pour un volume de données faible : chaque
# écriture recalcule les vues dans la foulée. Si la volumétrie augmente (latence
# d'écriture, verrous de lecture), revenir au job coalescé supprimé le
# 2026-07-15 (RefreshDashboardViewsJob, cf. historique git : DIRTY/INFLIGHT +
# verrou consultatif + REFRESH CONCURRENTLY).
module DashboardRefreshable
  extend ActiveSupport::Concern

  VIEWS = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  # Colonnes d'Intervention qui influent sur les graphiques du dashboard.
  DASHBOARD_COLUMNS = %w[workflow_state temps_total co2 service_id adherent_id début].freeze

  # concurrently: false — seule variante permise dans une transaction (fixtures
  # de test) ; verrou de lecture le temps du refresh, négligeable à ce volume.
  def self.refresh_views!
    VIEWS.each do |view|
      Scenic.database.refresh_materialized_view(view, concurrently: false, cascade: false)
    end
  end

  # Publique pour permettre un refresh manuel en cas de besoin (console) :
  # une_intervention.refresh_dashboard_views — ou, sans instance :
  # DashboardRefreshable.refresh_views!
  def refresh_dashboard_views
    DashboardRefreshable.refresh_views!

    # Version complexifié qui permettrait de regrouper les refresh, s'il y en a trop
    # RefreshDashboardViewsJob.request_refresh
  end

  private

  # true si la mise à jour touche une colonne affichée dans le dashboard
  # (évite de rafraîchir pour une modif sans impact, ex. description).
  def dashboard_relevant_change?
    saved_changes.keys.intersect?(DASHBOARD_COLUMNS)
  end
end
