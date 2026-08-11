# frozen_string_literal: true

# Le rafraîchissement des vues du dashboard est assuré par des triggers Postgres
# (db/triggers/, db/functions/) : il n'y a plus de callback ici, sinon chaque
# sauvegarde rafraîchirait deux fois. Ce module ne garde que l'appel manuel,
# utilisé par les tests et par la console.
module DashboardRefreshable
  extend ActiveSupport::Concern

  VIEWS = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  # concurrently: false — seule variante permise dans une transaction (tests).
  def self.refresh_views!
    VIEWS.each do |view|
      Scenic.database.refresh_materialized_view(view, concurrently: false, cascade: false)
    end
  end
end
