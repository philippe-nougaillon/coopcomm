# frozen_string_literal: true

class ActualiserDashboard < ApplicationService
  VUES = %i[dashboard_intervention_stats dashboard_agent_stats].freeze
  REGROUPEMENT = :actualiser_dashboard_regroupé

  # Un seul rafraîchissement, à la fin du bloc, quel que soit le nombre d'appels qu'il déclenche.
  def self.regrouper
    return yield if ActiveSupport::IsolatedExecutionState[REGROUPEMENT]

    begin
      ActiveSupport::IsolatedExecutionState[REGROUPEMENT] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState.delete(REGROUPEMENT)
      call
    end
  end

  # CONCURRENTLY : les lecteurs ne sont pas bloqués pendant le refresh, et Postgres l'accepte dans une transaction (tests).
  def call
    return if ActiveSupport::IsolatedExecutionState[REGROUPEMENT]

    VUES.each { |vue| Scenic.database.refresh_materialized_view(vue, concurrently: true) }
  end
end
