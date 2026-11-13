# Éval d'AÏBBO sur Tool : les champs du contexte sémantique, dans son ordre (base et lancement : aibbo_eval_case.rb).
require_relative "aibbo_eval_case"

class ToolEval < AibboEvalCase
  test "AÏBBO retrouve un matériel dont le nom est écrit sans accent" do
    tools(:cisaille).update_columns(name: "DÉBROUSSAILLEUSE")

    assert_aibbo_cite [tools(:cisaille).name], "Avons-nous une debroussailleuse ?"
  end

  test "AÏBBO compte les matériels dont le nom contient un mot" do
    assert_aibbo_repond Tool.by_nom("outil").count, "Combien de matériels ont le mot outil dans leur nom ?"
  end

  test "AÏBBO retrouve un matériel d'après sa description" do
    assert_aibbo_cite [tools(:tondeuse).name], "Quel matériel roule correctement ?"
  end

  test "AÏBBO donne la marque d'un matériel" do
    assert_aibbo_cite [tools(:tondeuse).marque], "De quelle marque est la tondeuse ?"
  end

  test "AÏBBO donne le modèle d'un matériel" do
    assert_aibbo_cite [tools(:tondeuse).modèle], "Quel est le modèle de la tondeuse ?"
  end

  test "AÏBBO compte les interventions pour lesquelles un matériel est réservé" do
    assert_aibbo_repond tools(:cisaille).interventions.count, "Pour combien d'interventions la cisaille est-elle réservée ?"
  end

  test "AÏBBO prend le début et la fin prévus d'une intervention pas encore commencée pour dire quand le matériel est réservé" do
    travel_to Time.zone.local(2026, 3, 5, 18)
    interventions(:nettoyage_port).update_columns(début: nil, fin: nil,
                                                  début_prévue: Time.zone.local(2026, 3, 10, 8),
                                                  fin_prévue: Time.zone.local(2026, 3, 10, 17))
    jour = Date.new(2026, 3, 10).all_day

    assert_aibbo_repond tools(:camion).interventions.where("COALESCE(début, début_prévue) <= ? AND COALESCE(fin, fin_prévue) >= ?",
                                                           jour.end, jour.begin).count,
                        "Pour combien d'interventions le camion est-il réservé le 10 mars 2026 ?"
  end

  test "AÏBBO nomme la personne qui a réservé un matériel un jour donné" do
    travel_to Time.zone.local(2026, 3, 9, 18)
    reserver_le_rateau_pour_weil_le_10_mars

    assert_aibbo_cite tools(:rateau).mouvements.réservé.where(date: Date.new(2026, 3, 10)).map { |mouvement| mouvement.user.nom },
                      "Qui a réservé le rateau le 10 mars 2026 ?"
  end

  test "AÏBBO dit qu'un matériel tombé en panne avant un jour donné est encore en panne ce jour-là" do
    travel_to Time.zone.local(2026, 3, 13, 18)
    mouvements(:mouvement_tondeuse).update_columns(date: Date.new(2026, 3, 9))
    mouvements(:mouvement_tondeuse_fin).update_columns(date: Date.new(2026, 3, 12))

    assert_aibbo_repond tools(:tondeuse).est_encore_en_panne_le(Date.new(2026, 3, 11)),
                        "La tondeuse est-elle en panne le 11 mars 2026 ?"
  end

  test "AÏBBO dit qu'un matériel réservé un jour donné n'est pas disponible ce jour-là" do
    travel_to Time.zone.local(2026, 3, 9, 18)
    reserver_le_rateau_pour_weil_le_10_mars
    rateau = tools(:rateau)
    jour = Date.new(2026, 3, 10)

    assert_aibbo_repond !(rateau.est_encore_en_panne_le(jour) || rateau.mouvements.réservé.exists?(date: jour)),
                        "Le rateau est-il disponible le 10 mars 2026 ?"
  end

  test "AÏBBO cherche un matériel sur son nom propre, sans les mots qui le précisent" do
    assert_aibbo_cite [tools(:tondeuse).name], "Est-ce qu'on a une tondeuse à gazon ?"
  end

  private

  # La réservation de la fixture mouvement_adherent, déplacée sur le rateau au 10 mars 2026.
  def reserver_le_rateau_pour_weil_le_10_mars
    mouvements(:mouvement_adherent).update_columns(tool_id: tools(:rateau).id, user_id: users(:weil).id, date: Date.new(2026, 3, 10))
  end
end
