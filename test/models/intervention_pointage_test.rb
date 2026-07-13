# frozen_string_literal: true

require 'test_helper'

# Tests unitaires du « moteur » de pointage de l'Intervention : le calcul du
# temps, la duplication mère → fille au scan, et les helpers d'état associés.
# On couvre ici le cœur métier des deux parcours agent les plus courants
# (scan du QRCode / saisie a posteriori) indépendamment du contrôleur.
class InterventionPointageTest < ActiveSupport::TestCase
  # === Intervention#calc_temps_total (pur calculateur) ====================
  # Contrat : renvoie 0 si une date manque ou si fin <= début ; sinon
  # (fin - début, en heures) - temps_de_pause, multiplié par le nombre d'agents.
  #
  # NB : on part de fixtures PERSISTÉES pour que `agents.count` (qui interroge
  # la base) reflète un nombre d'agents déterministe (tonte_locaux : 1 agent ;
  # intervention_repete : 2 agents), puis on surcharge les dates EN MÉMOIRE.
  # Aucune sauvegarde : la méthode est un calculateur pur, on l'isole des
  # validations et des callbacks.

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

  # BUG confirmé (NON corrigé, cf. règle /tests). Le callback
  # `before_save :calc_temps_total` (app/models/intervention.rb:52) appelle une
  # méthode qui n'assigne qu'une VARIABLE LOCALE `temps_total`
  # (app/models/intervention.rb:363-373) sans jamais écrire `self.temps_total`.
  # Conséquence : une intervention sauvegardée avec début/fin ne voit PAS son
  # temps_total recalculé automatiquement. Le pointage-terminer s'en sort car le
  # contrôleur assigne explicitement (interventions_controller.rb:364), mais la
  # « saisie a posteriori » (parcours 2) dépend entièrement du champ envoyé par
  # le formulaire. Ce test décrit le comportement ATTENDU ; il passera au vert à
  # la correction (assigner `self.temps_total = ...` dans calc_temps_total).
  test 'BUG : temps_total devrait être recalculé automatiquement à la sauvegarde' do
    skip 'Bug connu : before_save calc_temps_total ne persiste pas self.temps_total (intervention.rb:52,363)'

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

  # === Intervention#create_next_intervention (scan → clock in) ============
  # Duplique le modèle répété en une intervention « fille » du jour, rattachée
  # au seul agent qui vient de scanner.

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
end
