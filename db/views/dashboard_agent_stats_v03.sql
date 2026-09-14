-- Temps total imputé à chaque agent, au grain (organisation, agent).
-- Le temps d'une intervention est réparti entre TOUS ses agents, y compris ceux
-- dont le compte a été désactivé (gem discard) : leur part reste comptabilisée,
-- et le dashboard l'affiche sous le libellé « Utilisateur désactivé ».
-- Conséquence voulue : le total par organisation est conservé quand un agent est
-- désactivé, et la vue ne dépend plus de users.discarded_at — donc désactiver un
-- compte ne la rend plus périmée.
SELECT
  services.organisation_id                                   AS organisation_id,
  agent_interventions.agent_id                               AS agent_id,
  COALESCE(SUM(interventions.temps_total / nb_agents.cnt), 0) AS temps_total
FROM agent_interventions
JOIN users         ON users.id = agent_interventions.agent_id
JOIN interventions ON interventions.id = agent_interventions.intervention_id
JOIN services      ON services.id = interventions.service_id
JOIN (
  SELECT ai.intervention_id, COUNT(*) AS cnt
  FROM agent_interventions ai
  JOIN users u ON u.id = ai.agent_id
  GROUP BY ai.intervention_id
) nb_agents ON nb_agents.intervention_id = agent_interventions.intervention_id
GROUP BY services.organisation_id, agent_interventions.agent_id
