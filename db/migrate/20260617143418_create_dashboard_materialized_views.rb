# frozen_string_literal: true

class CreateDashboardMaterializedViews < ActiveRecord::Migration[8.0]
  def change
    # Vues MATÉRIALISÉES (résultat précalculé, stocké sur disque) qui alimentent
    # les graphiques du dashboard. Rafraîchies par RefreshDashboardViewsJob.
    create_view :dashboard_intervention_stats, materialized: true
    create_view :dashboard_agent_stats, materialized: true

    # Index UNIQUE sur le grain complet de chaque vue : INDISPENSABLE pour
    # REFRESH MATERIALIZED VIEW CONCURRENTLY (refresh sans verrouiller la lecture).
    # Le GROUP BY de chaque vue garantit l'unicité de ces colonnes.
    add_index :dashboard_intervention_stats,
              %i[organisation_id service_id adherent_id mois workflow_state],
              unique: true, name: 'idx_dashboard_intervention_stats_unique'

    add_index :dashboard_agent_stats,
              %i[organisation_id agent_id],
              unique: true, name: 'idx_dashboard_agent_stats_unique'
  end
end
