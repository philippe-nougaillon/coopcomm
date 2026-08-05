-- Les colonnes listées sont celles que lisent db/views/dashboard_*.sql : modifier
-- une description ou un commentaire ne déclenche donc aucun rafraîchissement.
-- Postgres déclenche le trigger dès que la colonne figure dans le SET, même si la
-- valeur ne change pas — équivalent au filtre Ruby qu'il remplace.
CREATE TRIGGER interventions_refresh_dashboard
AFTER INSERT OR DELETE OR UPDATE OF workflow_state, temps_total, co2, service_id, adherent_id, "début"
ON interventions
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_dashboard_views();
