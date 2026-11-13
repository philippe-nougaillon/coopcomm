# Éval d'AÏBBO sur User : les champs du contexte sémantique, dans son ordre (base et lancement : aibbo_eval_case.rb).
require_relative "aibbo_eval_case"

class UserEval < AibboEvalCase
  test "AÏBBO compte les adhérents par leur rôle" do
    assert_response_aibbo User.adhérent.count, "Combien y a-t-il d'adhérents ?"
  end

  test "AÏBBO compte parmi ceux qui réalisent des interventions les managers et les administrateurs, pas seulement les agents" do
    assert_response_aibbo User.intervenants.count, "Combien de personnes peuvent réaliser des interventions ?"
  end

  test "AÏBBO retrouve un utilisateur nommé par son prénom suivi de son nom" do
    assert_response_aibbo User.search_with_generic_name("james bond").count, "Combien d'utilisateurs s'appellent James Bond ?"
  end

  test "AÏBBO retrouve un utilisateur dont le nom est écrit sans accent" do
    assert_response_aibbo User.search_with_generic_name("thiaucourt-regnieville").count,
                          "Combien d'utilisateurs s'appellent Thiaucourt-Regnieville ?"
  end

  test "AÏBBO compte les interventions réalisées par un agent" do
    assert_response_aibbo Intervention.by_agent("michel martin").count, "Sur combien d'interventions Michel Martin est-il intervenu ?"
  end

  test "AÏBBO compte les interventions demandées par un adhérent, pas celles qu'il réalise" do
    assert_response_aibbo users(:weil).interventions_adherent.count, "Combien d'interventions l'adhérent Weil a-t-il demandées ?"
  end

  test "AÏBBO compte tous les services d'un utilisateur rattaché à plusieurs" do
    assert_response_aibbo users(:hidalgo).services.count, "Dans combien de services travaille Anne Hidalgo ?"
  end
end
