# Éval d'AÏBBO sur Service : les champs du contexte sémantique, dans son ordre (base et lancement : aibbo_eval_case.rb).
require_relative "aibbo_eval_case"

class ServiceEval < AibboEvalCase
  test "AÏBBO retrouve un service qui existe avec le nom" do
    assert_response_aibbo true, "Est-ce que le service secretariat existe ?"
  end

  test "AÏBBO compte les services dont le temps de trajet est calculé" do
    assert_response_aibbo Service.where(calculate_distance: true).count,
                          "Pour combien de services le temps de trajet jusqu'aux adhérents est-il calculé ?"
  end

  test "AÏBBO compte les interventions prises en charge par un service" do
    assert_response_aibbo services(:technique).interventions.count,
                          "Combien d'interventions le service technique a-t-il en charge ?"
  end

  test "AÏBBO compte les adhérents d'un service sans y mêler ses autres membres" do
    assert_response_aibbo services(:technique).users.adhérent.count, "Combien d'adhérents sont rattachés au service technique ?"
  end

  test "AÏBBO compte parmi ceux qui réalisent les interventions d'un service les managers et les administrateurs" do
    assert_response_aibbo services(:technique).users.intervenants.count,
                          "Combien de membres du service technique peuvent réaliser des interventions ?"
  end

  test "AÏBBO compte les managers d'un service" do
    assert_response_aibbo services(:technique).managers.count, "Combien de managers encadrent le service technique ?"
  end
end
