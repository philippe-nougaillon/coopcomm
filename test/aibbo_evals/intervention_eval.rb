# Éval d'AÏBBO sur Intervention : les champs du contexte sémantique, dans son ordre (base et lancement : aibbo_eval_case.rb).
require_relative "aibbo_eval_case"

class InterventionEval < AibboEvalCase
  # Les fixtures datées le sont en 2024, en 2025 ou autour du jour du lancement : mars 2026 n'en croise aucune.
  MAINTENANT = Time.zone.local(2026, 3, 13, 18)

  test "AÏBBO distingue les interventions terminées de celles déjà validées" do
    assert_response_aibbo Intervention.where(workflow_state: "terminé").count,
                          "Combien d'interventions sont terminées et attendent d'être validées ?"
  end

  test "AÏBBO compte les interventions qui restent à faire" do
    assert_response_aibbo Intervention.where(workflow_state: "nouveau").count, "Combien d'interventions reste-t-il à faire ?"
  end

  test "AÏBBO reconnaît une intervention créée sans titre à son titre en # suivi de l'identifiant" do
    [interventions(:demande_par_mail), interventions(:intervention_sans_manager)].each do |intervention|
      intervention.update_columns(description: "##{intervention.id}")
    end

    assert_response_aibbo Intervention.where("description ~ '^#[0-9]+$'").count, "Combien d'interventions ont été créées sans titre ?"
  end

  test "AÏBBO lit le début prévu, pas le début réel, pour ce qui devait commencer un jour donné" do
    travel_to MAINTENANT
    dater_quatre_interventions_en_mars

    assert_response_aibbo Intervention.where(début_prévue: Date.new(2026, 3, 10).all_day).count,
                          "Combien d'interventions devaient commencer le 10 mars 2026 ?"
  end

  test "AÏBBO lit la fin prévue, pas la fin réelle, pour ce qui devait se terminer un jour donné" do
    travel_to MAINTENANT
    dater_quatre_interventions_en_mars

    assert_response_aibbo Intervention.where(fin_prévue: Date.new(2026, 3, 11).all_day).count,
                          "Combien d'interventions devaient se terminer le 11 mars 2026 ?"
  end

  test "AÏBBO lit le début réel, pas le début prévu, pour ce qui a commencé un jour donné" do
    travel_to MAINTENANT
    dater_quatre_interventions_en_mars

    assert_response_aibbo Intervention.where(début: Date.new(2026, 3, 12).all_day).count,
                          "Combien d'interventions ont commencé le 12 mars 2026 ?"
  end

  test "AÏBBO lit la fin réelle, pas la fin prévue, pour ce qui s'est terminé un jour donné" do
    travel_to MAINTENANT
    dater_quatre_interventions_en_mars

    assert_response_aibbo Intervention.where(fin: Date.new(2026, 3, 12).all_day).count,
                          "Combien d'interventions se sont terminées le 12 mars 2026 ?"
  end

  test "AÏBBO donne le temps de pause d'une intervention" do
    assert_response_aibbo interventions(:tonte_locaux).temps_de_pause,
                          "Combien d'heures de pause ont été prises sur l'intervention « Tonte locaux » ?"
  end

  test "AÏBBO donne le temps total d'une intervention, tous agents additionnés" do
    intervention = tailler_les_arbres_a_deux_agents_huit_heures_chacun

    assert_response_aibbo intervention.temps_total,
                          "Combien d'heures de travail ont été passées sur l'intervention « Tailler les arbres », tous agents confondus ?"
  end

  test "AÏBBO divise le temps total par le nombre d'agents pour le temps d'un seul agent" do
    intervention = tailler_les_arbres_a_deux_agents_huit_heures_chacun

    assert_response_aibbo intervention.temps_par_agent,
                          "Combien d'heures Michel Martin a-t-il travaillé sur l'intervention « Tailler les arbres » ?"
  end

  test "AÏBBO compte tous les pointages sans y mêler les interventions maîtresses" do
    maitresse_a_deux_pointages

    assert_response_aibbo Intervention.where.not(template_slug: nil).count, "Combien de pointages ont été enregistrés en tout ?"
  end

  test "AÏBBO nomme l'adhérent qui a demandé une intervention" do
    assert_response_aibbo_contain [interventions(:nettoyage_port).adherent.nom], "Quel adhérent a demandé l'intervention « Nettoyage Marseille » ?"
  end

  test "AÏBBO compte parmi les intervenants d'une intervention le manager qui y a travaillé" do
    intervention = tailler_les_arbres_avec_un_manager_parmi_les_agents

    assert_response_aibbo intervention.agents.count, "Combien de personnes ont travaillé sur l'intervention « Tailler les arbres » ?"
  end

  test "AÏBBO nomme tous les intervenants d'une intervention, manager compris" do
    intervention = tailler_les_arbres_avec_un_manager_parmi_les_agents

    assert_response_aibbo_contain intervention.agents.pluck(:nom), "Qui a travaillé sur l'intervention « Tailler les arbres » ?"
  end

  test "AÏBBO compte les interventions d'un service" do
    assert_response_aibbo Intervention.where(service: Service.by_nom("technique")).count,
                          "Combien d'interventions pour le service technique ?"
  end

  test "AÏBBO retrouve le service d'une intervention quand son nom est écrit sans accent" do
    interventions(:intervention_validé).update_columns(service_id: services(:periscolaire).id)

    assert_response_aibbo Intervention.where(service: Service.by_nom("periscolaire")).count,
                          "Combien d'interventions pour le service periscolaire ?"
  end

  test "AÏBBO nomme le matériel réservé pour une intervention" do
    assert_response_aibbo_contain interventions(:tonte_locaux).tools.pluck(:name), "Quel matériel est réservé pour l'intervention « Tonte locaux » ?"
  end

  test "AÏBBO retrouve un adhérent désigné par « la mairie de » et écrit sans accent" do
    [interventions(:demande_par_mail_marseille), interventions(:intervention_sans_manager)].each do |intervention|
      intervention.update_columns(adherent_id: users(:adherent_nom_long).id)
    end

    assert_response_aibbo Intervention.by_adherent("thiaucourt-regnieville").count,
                          "Combien d'interventions a demandées la mairie de Thiaucourt-Regnieville ?"
  end

  test "AÏBBO retrouve un adhérent désigné par « la commune de »" do
    assert_response_aibbo Intervention.by_adherent("berthout").count, "Combien d'interventions a demandées la commune de Berthout ?"
  end

  test "AÏBBO compte les interventions d'un agent dont le prénom est écrit sans accent" do
    assert_response_aibbo Intervention.by_agent("rene").count, "Combien d'interventions a faites Rene ?"
  end

  test "AÏBBO croise les interventions d'un agent avec celles d'un adhérent" do
    assert_response_aibbo Intervention.by_agent("james bond").by_adherent("weil").count,
                          "Combien d'interventions James Bond a-t-il faites pour Weil ?"
  end

  test "AÏBBO compte les pointages d'une intervention de pointage désignée par son titre" do
    maitresse = maitresse_a_deux_pointages

    assert_response_aibbo maitresse.pointages.count,
                          "Combien de pointages ont été faits sur l'intervention « #{maitresse.description} » ?"
  end

  private

  # Le prévu et le réel tombent des jours différents : lire une colonne pour l'autre change chaque compte.
  def dater_quatre_interventions_en_mars
    interventions(:nouvelle_intervention).update_columns(début_prévue: mars(10, 8), fin_prévue: mars(10, 12),
                                                         début: mars(11, 8), fin: mars(11, 12))
    interventions(:intervention_terminée).update_columns(début_prévue: mars(10, 13), fin_prévue: mars(11, 17),
                                                         début: mars(10, 13), fin: mars(10, 17))
    interventions(:intervention_autre_agent).update_columns(début_prévue: mars(9, 8), fin_prévue: mars(9, 17),
                                                            début: mars(11, 14), fin: mars(12, 12))
    interventions(:intervention_autre_adhérent).update_columns(début_prévue: mars(11, 8), fin_prévue: mars(11, 12),
                                                               début: mars(12, 8), fin: mars(12, 12))
  end

  def mars(jour, heure)
    Time.zone.local(2026, 3, jour, heure)
  end

  # 8 h 30 → 17 h 30 avec 1 h de pause, deux agents : 16 h au total, 8 h chacun.
  def tailler_les_arbres_a_deux_agents_huit_heures_chacun
    interventions(:intervention_terminée).tap { |intervention| intervention.update_columns(temps_de_pause: 1, temps_total: 16) }
  end

  # Les deux agents des fixtures, plus un manager : un filtre User.agent en perd un.
  def tailler_les_arbres_avec_un_manager_parmi_les_agents
    AgentIntervention.create!(agent: users(:hidalgo), intervention: interventions(:intervention_terminée))
    interventions(:intervention_terminée)
  end

  # Deux interventions maîtresses : l'une a deux pointages, l'autre un seul. Rend la première.
  def maitresse_a_deux_pointages
    maitresse = interventions(:intervention_repete)
    autre_maitresse = interventions(:nettoyage_port)
    maitresse.update_columns(workflow_state: Intervention::POINTAGE_ACTIVE)
    autre_maitresse.update_columns(workflow_state: Intervention::POINTAGE_ACTIVE)
    rattacher_en_pointage(interventions(:intervention_fille), maitresse)
    rattacher_en_pointage(interventions(:nouvelle_intervention), maitresse)
    rattacher_en_pointage(interventions(:intervention_paris), autre_maitresse)
    maitresse
  end

  # Un pointage est une copie de sa maîtresse : même titre, et le slug de la maîtresse dans template_slug.
  def rattacher_en_pointage(intervention, maitresse)
    intervention.update_columns(template_slug: maitresse.slug, description: maitresse.description)
  end
end
