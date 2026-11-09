-- Paramètre de session posé par FetchBoxcarsInfos ; absent ou vidé par RESET (''), la vue ne rend aucune ligne.
SELECT interventions.*
FROM interventions
JOIN services ON services.id = interventions.service_id
WHERE services.organisation_id = NULLIF(current_setting('app.organisation_id', true), '')::bigint
