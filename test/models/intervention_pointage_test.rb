# frozen_string_literal: true

require 'test_helper'

# Tests unitaires du « moteur » de pointage de l'Intervention : le calcul du temps, la
# duplication mère → fille au scan, et les helpers d'état associés.
class InterventionPointageTest < ActiveSupport::TestCase
  # ==================== TESTS CRITIQUES ====================
  # Le temps total est facturé aux communes
  # en dépend directement).

  # === Intervention#calc_temps_total (pur calculateur) ====================
  # Contrat : renvoie 0 si une date manque ou si fin <= début ; sinon (fin - début, en
  # heures) - temps_de_pause, multiplié par le nombre d'agents.

  test 'calc_temps_total : durée simple sans pause, un agent' do
    i = interventions(:tonte_locaux) # 1 agent (bond)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0

    assert_equal 1, i.agents.count, 'préalable : la fixture doit avoir un seul agent'
    assert_in_delta 3.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : la pause est soustraite de la durée' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0.5

    assert_in_delta 2.5, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : le temps est multiplié par le nombre d agents' do
    i = interventions(:intervention_repete) # 2 agents (martin + bond)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0

    assert_equal 2, i.agents.count, 'préalable : la fixture doit avoir deux agents'
    assert_in_delta 6.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : une fin antérieure au début renvoie 0' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref - 1.hour

    assert_equal 0, i.calc_temps_total
  end

  test 'calc_temps_total : une date manquante renvoie 0' do
    i = interventions(:tonte_locaux)
    i.fin = nil

    assert_equal 0, i.calc_temps_total
  end

  test 'temps_total est recalculé et persisté à la sauvegarde' do
    i = Intervention.new(
      description: 'Saisie a posteriori',
      adherent: users(:weil),
      service: services(:technique),
      début: 3.hours.ago,
      fin: 1.hour.ago,
      temps_de_pause: 0,
      workflow_state: 'terminé'
    )
    i.agents = [users(:martin_technique_paris)]
    i.save!

    assert_in_delta 2.0, i.reload.temps_total, 1e-6
  end

  # Régression : sur un enregistrement neuf, agents.count interroge la base avec un
  # owner_id nil et renvoie 0, ce qui enregistrerait un temps_total nul à la création.
  test 'temps_total est multiplié par le nombre d agents dès la création' do
    i = Intervention.new(
      description: "Bon d'intervention à deux",
      adherent: users(:weil),
      service: services(:technique),
      début: 3.hours.ago,
      fin: 1.hour.ago,
      temps_de_pause: 0,
      workflow_state: 'terminé'
    )
    i.agents = [users(:john_wick), users(:nettoyage)]
    i.save!

    assert_in_delta 4.0, i.reload.temps_total, 1e-6
  end

  test 'temps_total est recalculé quand les dates changent' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 0)

    assert_in_delta 3.0, i.reload.temps_total, 1e-6

    i.update!(fin: i.début + 1.hour)

    assert_in_delta 1.0, i.reload.temps_total, 1e-6
  end

  test 'la pause est déduite du temps_total persisté' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 0.5)

    assert_in_delta 2.5, i.reload.temps_total, 1e-6
  end

  # === temps_de_pause : toujours renseigné ================================
  # Aucun chemin de terminaison (tâche rake, bouton « Terminer », Twilio) ne fournit de
  # pause : à défaut, elle vaut 0 et le temps total reste calculable.

  test 'une pause absente vaut 0 dès la validation' do
    i = interventions(:tonte_locaux)
    i.temps_de_pause = nil

    i.valid?

    assert_equal 0, i.temps_de_pause
  end

  test 'terminer une intervention sans pause renseignée enregistre une pause à 0' do
    i = interventions(:nouvelle_intervention) # 2 agents
    # 3 jours en arrière : hors du pointage ouvert de martin (fixture intervention_fille).
    i.update_columns(temps_de_pause: nil, temps_total: nil,
                     début: 3.days.ago, fin: 3.days.ago + 3.hours)

    i.reload.terminer!

    assert_equal 0, i.reload.temps_de_pause
    assert_in_delta 6.0, i.temps_total, 1e-6
  end

  # === Intervention#create_next_intervention (scan → clock in) ============
  # Duplique le modèle répété en une intervention « fille » du jour, rattachée au seul
  # agent qui vient de scanner.

  test 'create_next_intervention : duplique le modèle en une fille datée du jour' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)

    fille = nil
    assert_difference('Intervention.count', 1) do
      fille = mère.create_next_intervention(mère, agent)
    end

    assert fille.persisted?, 'la fille doit être persistée'
    assert_equal mère.slug, fille.template_slug, 'la fille pointe vers le slug de son modèle'
    assert_equal false, fille.repeter, 'la fille n\'est pas elle-même un modèle répété'
    assert_equal 'nouveau', fille.workflow_state
    assert_nil fille.fin, 'la fille est ouverte (pas encore de pointage de fin)'
    assert_equal [agent.id], fille.agents.pluck(:id), 'seul l\'agent qui scanne est rattaché'
    assert_equal mère.service_id, fille.service_id
    assert_equal mère.adherent_id, fille.adherent_id
    assert_equal Date.today, fille.début.to_date
  end

  # === Intervention#pointages =============================================

  test 'pointages : renvoie toutes les filles du modèle' do
    mère = interventions(:intervention_repete)
    f1 = mère.create_next_intervention(mère, users(:martin_technique_paris))
    f2 = mère.create_next_intervention(mère, users(:bond))

    ids = mère.pointages.pluck(:id)
    assert_includes ids, f1.id
    assert_includes ids, f2.id
  end

  test 'pointages : sont triées par mise à jour décroissante' do
    mère = interventions(:intervention_repete)
    mère.create_next_intervention(mère, users(:bond))
    f_recente = mère.create_next_intervention(mère, users(:martin_technique_paris))
    f_recente.touch # devient la plus récemment modifiée, sans ambiguïté de timestamp

    assert_equal f_recente, mère.pointages.first
  end

  # === Intervention#intervention_mère =====================================

  test 'intervention_mère : une fille retrouve son modèle' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_equal mère, fille.intervention_mère
  end

  # === Intervention#pointage_de? ==========================================
  # Discriminant du bouton « Terminer » (helper terminer_destination) : c'est
  # l'AFFECTATION au modèle qui compte, jamais le rôle.

  test 'pointage_de? : vrai pour un agent affecté au modèle' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.pointage_de?(users(:martin_technique_paris))
  end

  test 'pointage_de? : vrai pour un manager choisi comme agent du modèle' do
    mère = interventions(:intervention_repete)
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: mère)
    fille = mère.create_next_intervention(mère, manager)

    assert fille.pointage_de?(manager)
  end

  test 'pointage_de? : faux pour qui n’est pas affecté au modèle' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_not fille.pointage_de?(users(:manager_paris))
  end

  test 'pointage_de? : faux hors pointage (aucun modèle)' do
    assert_not interventions(:tonte_locaux).pointage_de?(users(:bond))
  end

  # === Intervention#en_cours? =============================================

  test 'en_cours? : vrai quand maintenant est dans la fenêtre' do
    i = interventions(:tonte_locaux)
    i.début = 1.hour.ago
    i.fin = 1.hour.from_now

    assert i.en_cours?
  end

  test 'en_cours? : faux hors de la fenêtre' do
    i = interventions(:tonte_locaux)
    i.début = 3.hours.ago
    i.fin = 1.hour.ago

    assert_not i.en_cours?
  end

  test 'en_cours? : nil quand les dates sont absentes' do
    i = interventions(:tonte_locaux)
    i.début = nil
    i.fin = nil

    assert_nil i.en_cours?
  end

  # === Un seul agent sur une fille de pointage ============================
  # Une fille naît toujours avec l'unique agent qui a scanné ; seul le formulaire
  # d'édition peut lui en ajouter d'autres.

  test 'une fille de pointage à deux agents est refusée' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    fille.agents = [users(:martin_technique_paris), users(:john_wick)]

    assert_not fille.valid?
    assert_includes fille.errors.full_messages, Intervention::MESSAGE_AGENT_UNIQUE
  end

  test 'une fille de pointage sans agent est refusée' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    fille.agents = []

    assert_not fille.valid?
    assert_includes fille.errors.full_messages, Intervention::MESSAGE_AGENT_UNIQUE
  end

  test 'une fille de pointage à un seul agent reste valide' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.valid?, fille.errors.full_messages.to_sentence
  end

  test 'une intervention hors pointage accepte toujours plusieurs agents' do
    intervention = interventions(:intervention_repete) # martin + bond

    assert_nil intervention.template_slug
    assert_operator intervention.agents.size, :>, 1
    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end
end
