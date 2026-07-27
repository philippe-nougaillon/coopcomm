-- Temps total imputé à chaque agent, au grain (organisation, agent).
-- Reproduit la règle métier de DashboardData#temps_par_agent :
-- le temps d'une intervention est réparti à parts égales entre ses agents
-- (temps_total / nombre d'agents de l'intervention).
SELECT
  services.organisation_id                                   AS organisation_id,
  agent_interventions.agent_id                               AS agent_id,
  COALESCE(SUM(interventions.temps_total / nb_agents.cnt), 0) AS temps_total
FROM agent_interventions
JOIN interventions ON interventions.id = agent_interventions.intervention_id
JOIN services      ON services.id = interventions.service_id
JOIN (
  SELECT intervention_id, COUNT(*) AS cnt
  FROM agent_interventions
  GROUP BY intervention_id
) nb_agents ON nb_agents.intervention_id = agent_interventions.intervention_id
GROUP BY services.organisation_id, agent_interventions.agent_id
