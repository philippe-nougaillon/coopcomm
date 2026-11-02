# frozen_string_literal: true

class ActualiserDashboard < ApplicationService
  VUES = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  # CONCURRENTLY : les lecteurs ne sont pas bloqués pendant le refresh, et Postgres l'accepte dans une transaction (tests).
  def call
    VUES.each { |vue| Scenic.database.refresh_materialized_view(vue, concurrently: true) }
  end
end
