-- Rafraîchit les deux vues matérialisées du dashboard.
-- Appelée par des triggers FOR EACH STATEMENT : un seul rafraîchissement par
-- requête, quel que soit le nombre de lignes touchées — un UPDATE de masse coûte
-- donc autant qu'une modification unitaire.
-- CONCURRENTLY est impossible ici : interdit dans un bloc transactionnel, et un
-- trigger s'exécute toujours dans la transaction de la requête.
CREATE OR REPLACE FUNCTION refresh_dashboard_views() RETURNS trigger AS $$
BEGIN
  REFRESH MATERIALIZED VIEW dashboard_intervention_stats;
  REFRESH MATERIALIZED VIEW dashboard_agent_stats;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
