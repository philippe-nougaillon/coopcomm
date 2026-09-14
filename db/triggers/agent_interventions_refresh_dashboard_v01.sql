-- L'affectation ou le retrait d'un agent change la répartition du temps par agent.
-- Couvre aussi les retraits en delete_all, que les callbacks Rails ne voient pas.
CREATE TRIGGER agent_interventions_refresh_dashboard
AFTER INSERT OR DELETE OR UPDATE OF agent_id, intervention_id
ON agent_interventions
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_dashboard_views();
