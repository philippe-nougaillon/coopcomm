# frozen_string_literal: true

# Déclenche (de façon coalescée) le rafraîchissement des vues matérialisées du
# dashboard quand une donnée qui les alimente change. Inclus dans Intervention
# et AgentIntervention.
module DashboardRefreshable
  extend ActiveSupport::Concern

  # Colonnes d'Intervention qui influent sur les graphiques du dashboard.
  DASHBOARD_COLUMNS = %w[workflow_state temps_total co2 service_id adherent_id début].freeze

  private

  def enqueue_dashboard_refresh
    RefreshDashboardViewsJob.request_refresh
  end

  # true si la mise à jour touche une colonne affichée dans le dashboard
  # (évite de rafraîchir pour une modif sans impact, ex. description).
  def dashboard_relevant_change?
    saved_changes.keys.intersect?(DASHBOARD_COLUMNS)
  end
end
