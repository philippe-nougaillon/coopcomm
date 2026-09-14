# frozen_string_literal: true

# Dormant : DashboardRefreshable rafraîchit les vues en synchrone. Regroupe les
# refresh d'une rafale d'écritures — DIRTY_KEY = du nouveau à refléter,
# INFLIGHT_KEY = un seul job en vol, verrou Postgres = un seul REFRESH à la fois.
class RefreshDashboardViewsJob < ApplicationJob
  queue_as :default

  VIEWS = %i[dashboard_intervention_stats dashboard_agent_stats].freeze

  DIRTY_KEY    = 'dashboard_views_dirty'
  INFLIGHT_KEY = 'dashboard_views_refresh_inflight'
  # TTL de sécurité si un worker meurt sans libérer le drapeau.
  INFLIGHT_TTL = 15.minutes
  ADVISORY_LOCK_ID = 4_915_201

  def self.request_refresh
    Rails.cache.write(DIRTY_KEY, true)
    return unless Rails.cache.write(INFLIGHT_KEY, true, unless_exist: true, expires_in: INFLIGHT_TTL)

    perform_later
  end

  # concurrently: false pour les tests — interdit dans une transaction.
  def self.refresh!(concurrently: true)
    VIEWS.each do |view|
      Scenic.database.refresh_materialized_view(view, concurrently: concurrently, cascade: false)
    end
  end

  def perform
    connection = ActiveRecord::Base.connection

    unless connection.select_value("SELECT pg_try_advisory_lock(#{ADVISORY_LOCK_ID})")
      Rails.cache.write(DIRTY_KEY, true)
      return
    end

    begin
      # Consommer le drapeau AVANT le refresh : une écriture pendant le refresh le repose.
      self.class.refresh!(concurrently: true) while Rails.cache.delete(DIRTY_KEY)
    ensure
      connection.execute("SELECT pg_advisory_unlock(#{ADVISORY_LOCK_ID})")
      Rails.cache.delete(INFLIGHT_KEY)
      if Rails.cache.read(DIRTY_KEY) &&
         Rails.cache.write(INFLIGHT_KEY, true, unless_exist: true, expires_in: INFLIGHT_TTL)
        self.class.perform_later
      end
    end
  end
end
