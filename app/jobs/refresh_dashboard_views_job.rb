# frozen_string_literal: true

# Rafraîchit les vues matérialisées qui alimentent le dashboard.
#
# Déclenché par after_commit sur Intervention / AgentIntervention (cf.
# DashboardRefreshable) à CHAQUE changement, SANS délai (« immédiat »).
#
# Pour rester correct ET sûr à l'échelle (200 agents), le déclenchement immédiat
# est « fait correctement » : pattern leading + trailing.
#   - DIRTY_KEY     : posé à chaque écriture → « il y a du nouveau à refléter ».
#   - INFLIGHT_KEY  : au plus UN job en vol → pas d'inondation de la file.
#   - verrou Postgres : au plus UN REFRESH à la fois (CONCURRENTLY l'exige).
# Le job reboucle tant que DIRTY est posé : une écriture survenue PENDANT un
# refresh est donc toujours reprise au tour suivant → aucun changement perdu,
# et une rafale de N écritures se résout en ~1 recalcul au lieu de N.
class RefreshDashboardViewsJob < ApplicationJob
  queue_as :default

  VIEWS = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  DIRTY_KEY    = 'dashboard_views_dirty'
  INFLIGHT_KEY = 'dashboard_views_refresh_inflight'
  # TTL de sécurité : si un worker meurt sans libérer le drapeau, un nouveau
  # cycle pourra repartir passé ce délai.
  INFLIGHT_TTL = 15.minutes
  ADVISORY_LOCK_ID = 4_915_201

  # Appelé à chaque changement pertinent. Marque les vues « dirty » et n'enfile
  # un job que s'il n'y en a pas déjà un en vol (déclenchement immédiat, zéro délai).
  def self.request_refresh
    Rails.cache.write(DIRTY_KEY, true)
    return unless Rails.cache.write(INFLIGHT_KEY, true, unless_exist: true, expires_in: INFLIGHT_TTL)

    perform_later
  end

  # concurrently: true en prod (aucun verrou de lecture sur le dashboard).
  # concurrently: false pour les tests (fixtures transactionnelles : CONCURRENTLY
  # est interdit dans une transaction).
  def self.refresh!(concurrently: true)
    VIEWS.each do |view|
      Scenic.database.refresh_materialized_view(view, concurrently: concurrently, cascade: false)
    end
  end

  def perform
    connection = ActiveRecord::Base.connection

    unless connection.select_value("SELECT pg_try_advisory_lock(#{ADVISORY_LOCK_ID})")
      # Un refresh tourne déjà : il rebouclera grâce au drapeau dirty ci-dessous.
      Rails.cache.write(DIRTY_KEY, true)
      return
    end

    begin
      # Tant qu'il reste des changements en attente, on recalcule. Consommer le
      # drapeau AVANT le refresh : une écriture pendant le refresh le repose,
      # garantissant un tour de boucle supplémentaire (trailing).
      self.class.refresh!(concurrently: true) while Rails.cache.delete(DIRTY_KEY)
    ensure
      connection.execute("SELECT pg_advisory_unlock(#{ADVISORY_LOCK_ID})")
      Rails.cache.delete(INFLIGHT_KEY)
      # Course finale : une écriture a pu reposer DIRTY juste après notre dernière
      # vérification mais avant la libération du drapeau → on relance un cycle.
      if Rails.cache.read(DIRTY_KEY) &&
         Rails.cache.write(INFLIGHT_KEY, true, unless_exist: true, expires_in: INFLIGHT_TTL)
        self.class.perform_later
      end
    end
  end
end
