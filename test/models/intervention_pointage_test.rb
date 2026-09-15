# frozen_string_literal: true

require 'test_helper'

# Tests unitaires du « moteur » de pointage de l'Intervention : le calcul du temps, la
# duplication mère → fille au scan, et les helpers d'état associés.
class InterventionPointageTest < ActiveSupport::TestCase
  # ==================== TESTS CRITIQUES ====================
  # Le temps total est facturé aux communes.

  # Aucun chemin de terminaison (tâche rake, bouton « Terminer », webhook SMS) ne fournit
  # de pause : à défaut elle vaut 0, et le temps total reste calculable. Hors terminaison
  # elle reste vide : une pause à 0 doit être un choix, jamais un effet de bord.

  test 'temps_de_pause : pause absente sur une intervention terminée → 0 dès la validation (critique)' do
    i = interventions(:tonte_locaux)
    i.workflow_state = Intervention::TERMINE
    i.temps_de_pause = nil

    i.valid?

    assert_equal 0, i.temps_de_pause
  end

  test 'temps_de_pause : pause absente hors terminaison → reste vide (critique)' do
    i = interventions(:tonte_locaux)
    i.temps_de_pause = nil

    i.valid?

    assert_nil i.temps_de_pause
  end

  test 'temps_de_pause : création d\'une intervention planifiée → aucune pause inventée (critique)' do
    i = Intervention.create!(
      description: 'Intervention planifiée',
      adherent: users(:weil),
      service: services(:technique),
      début_prévue: 2.days.from_now,
      fin_prévue: 2.days.from_now + 2.hours
    )

    assert_nil i.reload.temps_de_pause
  end

  test 'temps_de_pause : terminaison sans pause renseignée → pause enregistrée à 0 (critique)' do
    i = interventions(:nouvelle_intervention)
    # Vendredi précédant le lundi de `tonte_locaux` : toujours passé, jamais en
    # conflit. `3.days.ago` tombait sur ce lundi tous les jeudis, et bond est
    # agent des deux interventions.
    veille = (Date.today - 1).beginning_of_week - 3.days
    i.update_columns(temps_de_pause: nil, temps_total: nil,
                     début: veille + 8.hours, fin: veille + 11.hours)

    i.reload.terminer!

    assert_equal 0, i.reload.temps_de_pause
    assert_in_delta 6.0, i.temps_total, 1e-6
  end

  # Contrat : renvoie 0 si une date manque ou si fin <= début ; sinon (fin - début, en
  # heures) - temps_de_pause, multiplié par le nombre d'agents AFFECTÉS (désactivés compris).

  test 'calc_temps_total : durée simple sans pause → durée × agents affectés (critique)' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0

    assert_equal 2, i.agent_interventions.size, 'préalable : la fixture doit avoir deux affectations'
    assert_in_delta 6.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : pause renseignée → déduite de la durée (critique)' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0.5

    assert_in_delta 5.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : plusieurs agents → temps multiplié par leur nombre (critique)' do
    i = interventions(:intervention_repete)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0

    assert_equal 2, i.agents.count, 'préalable : la fixture doit avoir deux agents'
    assert_in_delta 6.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : agent désactivé → compte toujours dans le multiplicateur (critique)' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref + 3.hours
    i.temps_de_pause = 0

    assert_equal 1, i.agents.size, 'préalable : un seul agent actif'
    assert_equal 2, i.agent_interventions.size, 'préalable : deux agents affectés'
    assert_in_delta 6.0, i.calc_temps_total, 1e-6
  end

  test 'calc_temps_total : agent désactivé après coup → temps enregistré inchangé (critique)' do
    i = interventions(:tonte_locaux)
    i.update!(début: Time.zone.local(2026, 3, 2, 9, 0), fin: Time.zone.local(2026, 3, 2, 17, 0),
              temps_de_pause: 0)
    avant = i.temps_total

    i.agents.first.discard

    assert_no_changes -> { i.reload.temps_total } do
      i.update!(description: 'modifiée après la désactivation')
    end
    assert_in_delta 16.0, avant, 1e-6, 'préalable : 8 h × 2 agents affectés'
  end

  test 'calc_temps_total : fin antérieure au début → 0 (critique)' do
    i = interventions(:tonte_locaux)
    ref = Time.zone.local(2026, 3, 2, 9, 0, 0)
    i.début = ref
    i.fin = ref - 1.hour

    assert_equal 0, i.calc_temps_total
  end

  test 'calc_temps_total : date manquante → 0 (critique)' do
    i = interventions(:tonte_locaux)
    i.fin = nil

    assert_equal 0, i.calc_temps_total
  end

  test 'calc_temps_total : sauvegarde → temps recalculé et persisté (critique)' do
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
  test 'calc_temps_total : création à deux agents → temps déjà multiplié (critique)' do
    i = Intervention.new(
      description: "Bon d'intervention à deux",
      adherent: users(:weil),
      service: services(:technique),
      début: 3.hours.ago,
      fin: 1.hour.ago,
      temps_de_pause: 0,
      workflow_state: 'terminé'
    )
    i.agents = [users(:électricité), users(:nettoyage)]
    i.save!

    assert_in_delta 4.0, i.reload.temps_total, 1e-6
  end

  test 'calc_temps_total : dates modifiées → temps persisté recalculé (critique)' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 0)

    assert_in_delta 6.0, i.reload.temps_total, 1e-6

    i.update!(fin: i.début + 1.hour)

    assert_in_delta 2.0, i.reload.temps_total, 1e-6
  end

  test 'calc_temps_total : pause modifiée → déduite du temps persisté (critique)' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 0.5)

    assert_in_delta 5.0, i.reload.temps_total, 1e-6
  end

  # Le calcul doit précéder les validations : sinon `pas_de_temps_total_negatif`
  # contrôle la valeur de la sauvegarde précédente et laisse passer le négatif.
  test 'pas_de_temps_total_negatif : pause plus longue que la durée → refusée (critique)' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 0)

    assert_not i.update(temps_de_pause: 5)
    assert_includes i.errors.full_messages, 'Le temps total ne peut pas être négatif.'
    assert_in_delta 6.0, i.reload.temps_total, 1e-6
  end

  test 'pas_de_temps_total_negatif : pause égale à la durée → acceptée, temps nul (critique)' do
    i = interventions(:tonte_locaux)
    i.update!(début: 4.hours.ago, fin: 1.hour.ago, temps_de_pause: 3)

    assert_equal 0, i.reload.temps_total
  end

  # Une fille naît toujours avec l'unique agent qui a scanné ; seul le formulaire
  # d'édition peut lui en ajouter d'autres.

  test 'agent_unique_si_pointage : fille à deux agents → refusée (critique)' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    fille.agents = [users(:martin_technique_paris), users(:john_wick)]

    assert_not fille.valid?
    assert_includes fille.errors.full_messages, Intervention::MESSAGE_AGENT_UNIQUE
  end

  test 'agent_unique_si_pointage : fille sans agent → refusée (critique)' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    fille.agents = []

    assert_not fille.valid?
    assert_includes fille.errors.full_messages, Intervention::MESSAGE_AGENT_UNIQUE
  end

  test 'agent_unique_si_pointage : fille à un seul agent → acceptée (critique)' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.valid?, fille.errors.full_messages.to_sentence
  end

  test 'agent_unique_si_pointage : intervention hors pointage → plusieurs agents acceptés (critique)' do
    intervention = interventions(:intervention_repete)

    assert_nil intervention.template_slug
    assert_operator intervention.agents.size, :>, 1
    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'create_next_intervention : scan du modèle → une fille du jour rattachée au scanneur' do
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

  test 'create_next_intervention : scan du modèle → le début enregistré est l\'instant du scan' do
    mère = interventions(:intervention_repete)

    travel_to Time.current.middle_of_day.change(sec: 37) do
      fille = mère.create_next_intervention(mère, users(:bond))

      assert_equal Time.current, fille.reload.début
    end
  end

  # Le modèle est RECHARGÉ avant chaque scan : au scan réel, `set_intervention` vient de
  # le lire et personne n'a touché à `tag_list`. Sur un enregistrement dont le cache de
  # mots clés est froid, `dup` n'en copie aucun — sans la ligne `new_intervention.tags`,
  # la fille naîtrait sans mots clés.
  test 'create_next_intervention : modèle porteur de mots clés → la fille en hérite' do
    interventions(:intervention_repete).update!(tag_list: 'tonte, espace vert')
    mère = Intervention.find(interventions(:intervention_repete).id)

    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_equal ['tonte', 'espace vert'], fille.reload.tag_list
  end

  test 'create_next_intervention : modèle modifié après coup → filles déjà créées inchangées' do
    interventions(:intervention_repete).update!(tag_list: 'tonte')
    mère = Intervention.find(interventions(:intervention_repete).id)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    mère.update!(tag_list: 'élagage')

    assert_equal ['tonte'], fille.reload.tag_list
  end

  test 'create_next_intervention : fille modifiée → modèle inchangé' do
    interventions(:intervention_repete).update!(tag_list: 'tonte')
    mère = Intervention.find(interventions(:intervention_repete).id)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    fille.update!(tag_list: 'élagage')

    assert_equal ['tonte'], mère.reload.tag_list
  end

  test 'pointages : modèle scanné plusieurs fois → toutes ses filles' do
    mère = interventions(:intervention_repete)
    f1 = mère.create_next_intervention(mère, users(:martin_technique_paris))
    f2 = mère.create_next_intervention(mère, users(:bond))

    ids = mère.pointages.pluck(:id)

    assert_includes ids, f1.id
    assert_includes ids, f2.id
  end

  test 'pointages : plusieurs filles → triées par mise à jour décroissante' do
    mère = interventions(:intervention_repete)
    mère.create_next_intervention(mère, users(:bond))
    récente = mère.create_next_intervention(mère, users(:martin_technique_paris))
    récente.touch

    assert_equal récente, mère.pointages.first
  end

  test 'en_cours? : instant présent dans la fenêtre → vrai' do
    i = interventions(:tonte_locaux)
    i.début = 1.hour.ago
    i.fin = 1.hour.from_now

    assert i.en_cours?
  end

  test 'en_cours? : instant présent hors de la fenêtre → faux' do
    i = interventions(:tonte_locaux)
    i.début = 3.hours.ago
    i.fin = 1.hour.ago

    assert_not i.en_cours?
  end

  test 'en_cours? : dates absentes → nil' do
    i = interventions(:tonte_locaux)
    i.début = nil
    i.fin = nil

    assert_nil i.en_cours?
  end

  test 'intervention_mère : fille de pointage → son modèle' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_equal mère, fille.intervention_mère
  end

  # Discriminant du bouton « Terminer » (helper terminer_destination) : c'est
  # l'AFFECTATION qui compte, jamais le rôle — au modèle ET à la fille affichée.

  test 'pointage_de? : agent affecté au modèle et scanneur de la fille → vrai' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.pointage_de?(users(:martin_technique_paris))
  end

  test 'pointage_de? : manager choisi comme agent du modèle → vrai' do
    mère = interventions(:intervention_repete)
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: mère)
    fille = mère.create_next_intervention(mère, manager)

    assert fille.pointage_de?(manager)
  end

  test 'pointage_de? : pointage d\'un autre agent du même modèle → faux' do
    mère = interventions(:intervention_repete)
    manager = users(:manager_paris)
    AgentIntervention.create!(agent: manager, intervention: mère)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert mère.agents.include?(manager), 'garde : affecté au modèle'
    assert_not fille.pointage_de?(manager)
  end

  test 'pointage_de? : personne non affectée au modèle → faux' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_not fille.pointage_de?(users(:manager_paris))
  end

  test 'pointage_de? : intervention hors pointage → faux' do
    assert_not interventions(:tonte_locaux).pointage_de?(users(:bond))
  end

  # `pointer` ne retrouve que le pointage du jour : ailleurs, le bouton
  # « Terminer » doit passer par le formulaire.

  test 'pointage_du_jour_de? : pointage ouvert aujourd\'hui → vrai' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.pointage_du_jour_de?(users(:martin_technique_paris))
  end

  test 'pointage_du_jour_de? : pointage resté ouvert un jour précédent → faux' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))
    fille.update_columns(début: 5.days.ago)

    assert fille.pointage_de?(users(:martin_technique_paris)), 'garde : la fille reste un pointage de cet agent'
    assert_not fille.pointage_du_jour_de?(users(:martin_technique_paris))
  end

  test 'pointage_du_jour_de? : pointage sans date de début → faux' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))
    fille.update_columns(début: nil)

    assert_not fille.pointage_du_jour_de?(users(:martin_technique_paris))
  end
end
