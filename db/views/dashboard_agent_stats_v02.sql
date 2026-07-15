-- Temps total imputé à chaque agent, au grain (organisation, agent).
-- Reproduit la règle métier de DashboardData#temps_par_agent : le temps d'une
-- intervention est réparti entre ses agents NON SUPPRIMÉS (temps_total / nb d'agents).
-- D'où la jointure sur `users` filtrée sur `discarded_at IS NULL` (gem discard,
-- default_scope :kept) — exactement comme l'association `Intervention#agents`,
-- aussi bien pour le diviseur (nb_agents.cnt) que pour les agents retenus.
SELECT
  services.organisation_id                                   AS organisation_id,
  agent_interventions.agent_id                               AS agent_id,
  COALESCE(SUM(interventions.temps_total / nb_agents.cnt), 0) AS temps_total
FROM agent_interventions
JOIN users         ON users.id = agent_interventions.agent_id AND users.discarded_at IS NULL
JOIN interventions ON interventions.id = agent_interventions.intervention_id
JOIN services      ON services.id = interventions.service_id
JOIN (
  SELECT ai.intervention_id, COUNT(*) AS cnt
  FROM agent_interventions ai
  JOIN users u ON u.id = ai.agent_id AND u.discarded_at IS NULL
  GROUP BY ai.intervention_id
) nb_agents ON nb_agents.intervention_id = agent_interventions.intervention_id
GROUP BY services.organisation_id, agent_interventions.agent_id
