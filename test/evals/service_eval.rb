# Éval d'AÏBBO sur Service : les champs du contexte sémantique, dans son ordre (base et lancement : aibbo_eval_case.rb).
require_relative "aibbo_eval_case"

class ServiceEval < AibboEvalCase
  test "AÏBBO retrouve un service dont le nom est écrit sans accent" do
    assert_aibbo_cite [services(:secretariat).nom], "Comment s'écrit exactement le nom du service secretariat ?"
  end

  test "AÏBBO compte les services dont le temps de trajet est calculé" do
    assert_aibbo_repond Service.where(calculate_distance: true).count,
                        "Pour combien de services le temps de trajet jusqu'aux adhérents est-il calculé ?"
  end

  test "AÏBBO compte les interventions prises en charge par un service" do
    assert_aibbo_repond services(:technique).interventions.count,
                        "Combien d'interventions le service technique a-t-il en charge ?"
  end

  test "AÏBBO compte les adhérents d'un service sans y mêler ses autres membres" do
    assert_aibbo_repond services(:technique).users.adhérent.count, "Combien d'adhérents sont rattachés au service technique ?"
  end

  test "AÏBBO compte parmi ceux qui réalisent les interventions d'un service les managers et les administrateurs" do
    assert_aibbo_repond services(:technique).users.intervenants.count,
                        "Combien de membres du service technique peuvent réaliser des interventions ?"
  end

  test "AÏBBO compte les managers d'un service" do
    assert_aibbo_repond services(:technique).managers.count, "Combien de managers encadrent le service technique ?"
  end

  test "AÏBBO cherche un service sur son nom propre, sans le mot « service »" do
    assert_aibbo_cite [services(:menage).nom], "Y a-t-il un service ménage ?"
  end
end
