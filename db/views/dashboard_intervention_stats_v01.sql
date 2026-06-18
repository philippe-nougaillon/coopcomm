-- Pré-agrégat des interventions au grain le plus fin utile au dashboard :
-- (organisation, service, adhérent, mois, statut workflow).
-- Le contrôleur re-filtre/re-agrège PAR-DESSUS cette vue (org, service, période)
-- pour produire chaque graphique — d'où des lectures quasi instantanées.
-- organisation_id est dérivé via services (les interventions n'ont pas la colonne).
SELECT
  services.organisation_id                              AS organisation_id,
  interventions.service_id                              AS service_id,
  interventions.adherent_id                             AS adherent_id,
  date_trunc('month', interventions."début")::date      AS mois,
  interventions.workflow_state                          AS workflow_state,
  COUNT(*)                                              AS nb,
  COALESCE(SUM(interventions.temps_total), 0)           AS temps_total,
  COALESCE(SUM(interventions.co2), 0)                   AS co2
FROM interventions
JOIN services ON services.id = interventions.service_id
GROUP BY
  services.organisation_id,
  interventions.service_id,
  interventions.adherent_id,
  date_trunc('month', interventions."début"),
  interventions.workflow_state
