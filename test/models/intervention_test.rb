# frozen_string_literal: true

require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  # Un attachement n'étant pas une colonne, audited n'écrit une ligne que si le
  # commentaire est renseigné : c'est ce commentaire qui fait exister l'audit.
  test 'pièce jointe : une photo ajoutée → un audit portant le libellé au singulier' do
    intervention = intervention_avec_photos

    assert_difference -> { intervention.audits.count }, 1 do
      intervention.update!(photos: [png])
    end
    assert_match(/1 photo ajoutée/i, intervention.audits.last.comment)
  end

  test 'pièce jointe : deux photos ajoutées → le libellé s\'accorde au pluriel' do
    intervention = intervention_avec_photos
    intervention.update!(photos: [png])

    intervention.update!(photos: intervention.photos.map(&:signed_id) + [png, png])

    assert_match(/2 photos ajoutées/i, intervention.audits.last.comment)
  end

  test 'pièce jointe : photo existante ré-émise par le formulaire → aucun faux message d\'ajout' do
    intervention = intervention_avec_photos
    intervention.update!(photos: [png])
    existante = intervention.photos.first

    intervention.update!(description: 'Titre modifié', photos: [existante.signed_id])

    assert_equal 1, intervention.reload.photos.count
    refute_match(/ajoutée/i, intervention.audits.last.comment.to_s)
  end

  # C'est la clé qui fait foi, pas l'association : User porte un default_scope
  # :kept, donc `adherent` rend nil dès que le compte est désactivé.
  test 'adhérent : compte désactivé après la création → intervention toujours valide' do
    adherent = users(:weil)
    intervention = intervention_sans_dates(adherent: adherent, service: services(:informatique))
    adherent.discard

    assert_nil intervention.reload_adherent
    assert_predicate intervention, :valid?
  end

  test 'adhérent : intervention existante dont l\'adhérent est désactivé → toujours enregistrable' do
    intervention = interventions(:tonte_locaux)
    intervention.adherent.discard

    intervention.reload

    assert_nil intervention.adherent
    assert_predicate intervention.adherent_id, :present?
    assert_predicate intervention, :valid?
  end

  test 'combine_datetime : heure et minute saisies à part → reportées sur la date' do
    intervention = interventions(:nouvelle_intervention)
    intervention.début_prévue = Time.zone.local(2030, 5, 4, 8, 0)
    intervention.début_prévue_hour = '14'
    intervention.début_prévue_minute = '45'

    intervention.valid?

    assert_equal 14, intervention.début_prévue.hour
    assert_equal 45, intervention.début_prévue.min
  end

  test 'combine_datetime : date absente → aucune heure inventée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.début_prévue = nil
    intervention.début_prévue_hour = '14'

    intervention.valid?

    assert_nil intervention.début_prévue
  end

  test 'set_temporary_description : création sans description → bouchon posé puis remplacé par l\'identifiant' do
    intervention = Intervention.create!(description: '', adherent: users(:weil), service: services(:informatique))

    assert_equal "##{intervention.id}", intervention.reload.description
  end

  test 'replace_description_with_id : création avec description → description conservée' do
    intervention = Intervention.create!(description: 'Réparer la porte', adherent: users(:weil),
                                        service: services(:informatique))

    assert_equal 'Réparer la porte', intervention.reload.description
  end

  test 'must_not_have_any_mouvements : intervention encore liée à un mouvement → suppression refusée' do
    intervention = interventions(:tonte_locaux)
    Mouvement.create!(tool: tools(:tondeuse), user: users(:bond), intervention: intervention,
                      état: :réservé, date: Time.zone.parse('2026-06-02 09:00'))

    assert_not intervention.destroy
    assert_includes intervention.errors.full_messages, 'Il reste des mouvements liés.'
    assert Intervention.exists?(intervention.id)
  end

  test 'check_workflow_pointage_mère : modèle qui cesse de se répéter → repasse à nouveau' do
    intervention = interventions(:intervention_repete)
    intervention.update_columns(workflow_state: 'pointage activé')

    intervention.repeter = false
    intervention.valid?

    assert_equal 'nouveau', intervention.workflow_state
  end

  test 'check_workflow_pointage_mère : intervention qui devient un modèle → passe à pointage activé' do
    intervention = interventions(:nouvelle_intervention)

    intervention.repeter = true
    intervention.valid?

    assert_equal 'pointage activé', intervention.workflow_state
  end

  test 'dates_obligatoires_si_terminé : terminée sans date de début → refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, début: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'dates_obligatoires_si_terminé : terminée sans date de fin → refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, fin: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'dates_obligatoires_si_terminé : terminée avec ses deux dates → acceptée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention, :valid?
  end

  test 'dates_obligatoires_si_terminé : autre état sans dates → accepté' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: nil, fin: nil)

    assert_predicate intervention, :valid?
  end

  test 'agent_obligatoire_si_terminé : terminée sans agent → refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all
    intervention.reload.workflow_state = Intervention::TERMINE

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join,
                    "Au moins un agent est obligatoire pour terminer l'intervention"
  end

  test 'agent_obligatoire_si_terminé : terminée avec un agent → acceptée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention.agents, :any?
    assert_predicate intervention, :valid?
  end

  test 'agent_obligatoire_si_terminé : autre état sans agent → accepté' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all

    assert_predicate intervention.reload, :valid?
  end

  test 'agent_obligatoire_si_terminé : intervention déjà terminée privée de ses agents → plus enregistrable' do
    intervention = interventions(:intervention_terminée)
    intervention.agents.destroy_all

    assert_not intervention.reload.update(commentaires: 'peu importe')
  end

  test 'agent_obligatoire_si_terminé : agents retirés d\'une intervention terminée → refusé' do
    intervention = interventions(:intervention_terminée)
    intervention.agent_ids = []

    assert_not intervention.valid?
  end

  # Seuls les administrateurs échappent à la règle côté agents.

  test 'service_partagé : adhérent étranger au service → refusé' do
    intervention = intervention_sans_dates(adherent: users(:berthout), service: services(:informatique))

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'adhérent #{users(:berthout).nom_prénom} n'appartient pas au service Informatique"
  end

  test 'service_partagé : adhérent du service → accepté' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:informatique))

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'service_partagé : agent étranger au service → refusé' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:john_wick)]

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{users(:john_wick).nom_prénom} n'appartient pas au service Technique"
  end

  test 'service_partagé : agent du service → accepté' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:martin_technique_paris)]

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'service_partagé : administrateur comme agent → accepté quel que soit son service' do
    admin = users(:philippe_super_admin)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [admin]

    assert_not_includes admin.service_ids, services(:technique).id
    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'service_partagé : manager comme agent hors de son service → refusé, aucune exemption' do
    manager = users(:manager_paris)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [manager]

    assert_not_includes manager.service_ids, services(:technique).id
    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{manager.nom_prénom} n'appartient pas au service Technique"
  end

  test 'service_partagé : service étranger à l\'adhérent comme aux agents → refusé des deux côtés' do
    intervention = interventions(:tonte_locaux)
    intervention.service = services(:secretariat)

    assert_not intervention.valid?
    assert_equal 2, intervention.errors.full_messages.count { |m| m.include?('Secrétariat') }
  end

  # temps_total est dérivé des dates et du nombre d'agents, jamais fixé à la main.

  test 'update_heures_consommees_convention : création → le temps s\'ajoute aux heures de la convention' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 3)
      create_intervention_conventionnee(heures: 5, début: 6.hours.ago)

      assert_equal 8, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : intervention d\'un autre service → heures inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, service: services(:technique))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : intervention d\'un autre adhérent → heures inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, adherent_id: users(:adhérent_sans_intervention).id)

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : intervention hors période → heures inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, début: Time.zone.parse('2025-06-01 06:00:00'))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : temps modifié → seule la différence est reportée' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)

      intervention.update!(fin: intervention.début + 5.hours)

      assert_equal 5, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : modification sans changement de temps → heures inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)

      intervention.update!(description: 'description modifiée')

      assert_equal 3, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'update_heures_consommees_convention : suppression → le temps est retranché' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)

      intervention.destroy!

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  # Le créateur est déduit de l'audit de création : au niveau modèle, il faut `as_user`
  # pour le poser (dans l'app, `audited` capte le current_user du contrôleur).

  test 'send_manager_notification : création non terminée par un agent → aucune notification' do
    agent = users(:martin_technique_paris)

    assert_no_enqueued_jobs only: [NotifManagersNewInterventionFromAdherentJob,
                                   NotifManagersInterventionDoneByAgentJob] do
      Audited.audit_class.as_user(agent) do
        Intervention.create!(description: 'Brouillon agent',
                             adherent_id: users(:patrick_adherent_paris).id,
                             service: services(:technique),
                             début_prévue: 1.day.from_now,
                             fin_prévue: 1.day.from_now + 1.hour)
      end
    end
  end

  test 'send_manager_notification : création sans utilisateur d\'audit → aucune notification' do
    assert_no_enqueued_jobs only: [NotifManagersNewInterventionFromAdherentJob,
                                   NotifManagersInterventionDoneByAgentJob] do
      Intervention.create!(description: 'Création système',
                           adherent_id: users(:weil).id,
                           service: services(:informatique),
                           début_prévue: 1.day.from_now,
                           fin_prévue: 1.day.from_now + 1.hour)
    end
  end

  # Les événements sont observés par les jobs qu'ils déclenchent : les mêmes
  # sondes que test/subscription.

  test 'apres_terminaison : intervention ordinaire terminée → workflow_changed et done publiés' do
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.terminer! }
      end
    end
  end

  test 'apres_terminaison : pointage terminé → workflow_changed et done publiés' do
    pointage = cree_pointage_termine_par(users(:martin_technique_paris))

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { pointage.terminer! }
      end
    end
  end

  test 'apres_terminaison : modification sans changement d\'état → aucun événement publié' do
    intervention = interventions(:intervention_terminée)

    assert_no_enqueued_jobs only: [NotifManagersWorkflowChangedJob, NotifAdherentInterventionTermineeJob] do
      Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.update!(commentaires: 'Relu') }
    end
  end

  test 'scope ordered : plusieurs interventions → la plus récemment mise à jour en tête' do
    récente = interventions(:nouvelle_intervention)
    récente.update_columns(updated_at: 1.minute.from_now)

    assert_equal récente, Intervention.ordered.first
  end

  test 'scope courantes : tous les états → seuls nouveau, pointage activé et terminé' do
    états = Intervention.courantes.pluck(:workflow_state).uniq

    assert_includes états, 'nouveau'
    assert_not_includes états, 'validé'
    assert_not_includes états, 'archivé'
  end

  test 'filter_by_service : services demandés → leurs interventions seulement' do
    filtrées = Intervention.filter_by_service([services(:technique)])

    assert filtrées.all? { |i| i.service_id == services(:technique).id }
    assert_includes filtrées, interventions(:tonte_locaux)
  end

  test 'by_role_for : manager → toutes les interventions, triées' do
    listées = Intervention.by_role_for(users(:hidalgo))

    assert_includes listées, interventions(:tonte_locaux)
    assert_includes listées, interventions(:intervention_autre_adhérent)
  end

  test 'by_role_for : adhérent → seulement les siennes' do
    listées = Intervention.by_role_for(users(:weil))

    assert listées.all? { |i| i.adherent_id == users(:weil).id }
  end

  test 'by_role_for : agent → seulement celles où il est affecté' do
    agent = users(:martin_technique_paris)

    listées = Intervention.by_role_for(agent)

    assert listées.all? { |i| i.agents.include?(agent) }
    assert_not_includes listées, interventions(:intervention_with_location)
  end

  test 'effective_début / effective_fin : dates réelles renseignées → elles priment sur les prévues' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: Time.zone.local(2030, 5, 4, 9), fin: Time.zone.local(2030, 5, 4, 11),
                                   début_prévue: Time.zone.local(2030, 5, 4, 14),
                                   fin_prévue: Time.zone.local(2030, 5, 4, 16))

    assert_equal Time.zone.local(2030, 5, 4, 9), intervention.effective_début
    assert_equal Time.zone.local(2030, 5, 4, 11), intervention.effective_fin
  end

  test 'effective_début / effective_fin : dates réelles absentes → repli sur les prévues' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: nil, fin: nil,
                                   début_prévue: Time.zone.local(2030, 5, 4, 14),
                                   fin_prévue: Time.zone.local(2030, 5, 4, 16))

    assert_equal Time.zone.local(2030, 5, 4, 14), intervention.effective_début
    assert_equal Time.zone.local(2030, 5, 4, 16), intervention.effective_fin
  end

  test 'pointage_ouvert? : fille de pointage sans fin → vrai' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.pointage_ouvert?
  end

  test 'pointage_ouvert? : fille de pointage clôturée → faux' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))
    fille.update_columns(fin: Time.current)

    assert_not fille.reload.pointage_ouvert?
  end

  test 'pointage_ouvert? : intervention hors pointage → faux' do
    assert_not interventions(:nouvelle_intervention).pointage_ouvert?
  end

  test 'durée_humanized : début et fin réels → durée en heures et minutes' do
    intervention = interventions(:nouvelle_intervention)
    intervention.début = Time.zone.local(2030, 5, 4, 9, 0)
    intervention.fin = Time.zone.local(2030, 5, 4, 11, 30)

    assert_equal '02h 30min', intervention.durée_humanized
  end

  test 'passed : intervention encore à l\'état nouveau et non finie → faux' do
    intervention = interventions(:nouvelle_intervention)
    intervention.fin = 1.hour.from_now

    assert_not intervention.passed
  end

  test 'passed : intervention nouveau dont la fin est dépassée → vrai' do
    intervention = interventions(:nouvelle_intervention)
    intervention.fin = 1.hour.ago

    assert intervention.passed
  end

  test 'passed : intervention sortie de l\'état nouveau → vrai' do
    assert interventions(:tonte_locaux).passed
  end

  test 'temps_par_agent : plusieurs agents affectés → le temps divisé entre eux' do
    intervention = interventions(:tonte_locaux)

    assert_in_delta intervention.temps_total / intervention.agents.count, intervention.temps_par_agent, 1e-6
  end

  test 'temps_par_agent : aucun agent → le temps entier, sans division par zéro' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all

    assert_equal intervention.reload.temps_total, intervention.temps_par_agent
  end

  test 'bon? : intervention créée par un agent → vrai' do
    intervention = nil
    Audited.audit_class.as_user(users(:martin_technique_paris)) do
      intervention = Intervention.create!(description: 'Bon agent', adherent: users(:weil),
                                          service: services(:informatique))
    end

    assert intervention.bon?
  end

  test 'bon? : intervention créée par un manager → faux' do
    intervention = nil
    Audited.audit_class.as_user(users(:hidalgo)) do
      intervention = Intervention.create!(description: 'Demande manager', adherent: users(:weil),
                                          service: services(:informatique))
    end

    assert_not intervention.bon?
  end

  test 'rgba : état courant → la couleur déclarée sur cet état' do
    assert_equal '0,181,255,255', interventions(:nouvelle_intervention).rgba
  end

  test 'workflow_states_count : un lot d\'interventions → chaque état compté, y compris à zéro' do
    comptes = Intervention.workflow_states_count(Intervention.where(id: interventions(:tonte_locaux).id))

    assert_equal 1, comptes['Validé']
    assert_equal 0, comptes['Nouveau']
    assert_equal Intervention.workflow_state_humanized.sort, comptes.keys.sort
  end

  # Côté agent le périmètre n'est pas restreint aux filles de pointage :
  # toutes ses interventions « nouveau » sont listées.

  test 'by_role_for_home : agent, intervention ordinaire à l\'état nouveau → listée' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    assert_nil intervention.template_slug
    assert_includes intervention.agents, agent

    assert_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'by_role_for_home : agent, fille de pointage à l\'état nouveau → listée' do
    agent = users(:martin_technique_paris)
    fille = interventions(:intervention_fille)
    fille.update_columns(template_slug: interventions(:intervention_repete).slug)

    assert_includes Intervention.by_role_for_home(agent), fille
  end

  test 'by_role_for_home : agent, interventions sorties de l\'état nouveau → exclues' do
    listées = Intervention.by_role_for_home(users(:martin_technique_paris))

    assert_not_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:intervention_validé)
  end

  test 'by_role_for_home : agent, intervention nouveau d\'un autre agent → exclue' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:intervention_with_location)

    assert_equal 'nouveau', intervention.workflow_state
    assert_not_includes intervention.agents, agent

    assert_not_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'by_role_for_home : agent, plusieurs interventions → triées par mise à jour décroissante' do
    agent = users(:martin_technique_paris)
    interventions(:intervention_paris).update_columns(updated_at: 1.minute.from_now)

    assert_equal interventions(:intervention_paris), Intervention.by_role_for_home(agent).first
  end

  test 'by_role_for_home : adhérent → seulement ses interventions terminées' do
    listées = Intervention.by_role_for_home(users(:weil))

    assert_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:nouvelle_intervention)
    assert_not_includes listées, interventions(:intervention_autre_adhérent)
  end

  test 'by_role_for_home : manager → interventions validées, refusées et archivées exclues' do
    listées = Intervention.by_role_for_home(users(:hidalgo))

    assert_includes listées, interventions(:nouvelle_intervention)
    assert_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:tonte_locaux)
  end

  test 'qrcode : URL fournie → un SVG' do
    svg = interventions(:intervention_repete).qrcode('https://example.test/pointer')

    assert_includes svg, '<svg'
  end

  test 'dernière_en_cours : intervention qui recouvre l\'instant présent → retenue' do
    agent = users(:nettoyage)
    en_cours = Intervention.create!(
      description: 'En cours maintenant', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, Intervention.dernière_en_cours(agent.interventions)
  end

  test 'dernière_en_cours : interventions sans date prévue → nil' do
    assert_nil Intervention.dernière_en_cours(Intervention.where(id: interventions(:nouvelle_intervention).id))
  end

  test 'extract_temps_total_depending_on_audit : audit sans variation de temps → zéro' do
    intervention = interventions(:tonte_locaux)
    audit = intervention.audits.build(action: 'update', audited_changes: { 'description' => %w[avant après] })

    assert_equal 0, intervention.send(:extract_temps_total_depending_on_audit, audit)
  end

  test 'extract_temps_total_depending_on_audit : audit de création → le temps enregistré' do
    intervention = interventions(:tonte_locaux)
    audit = intervention.audits.build(action: 'create', audited_changes: { 'temps_total' => 5 })

    assert_equal 5, intervention.send(:extract_temps_total_depending_on_audit, audit)
  end

  test 'broadcast_channels : intervention complète → organisation, service, adhérent et agents' do
    intervention = interventions(:tonte_locaux)

    channels = intervention.send(:broadcast_channels)

    assert_includes channels, "interventions_organisation_#{intervention.organisation.id}"
    assert_includes channels, "interventions_service_#{intervention.service_id}"
    assert_includes channels, "interventions_adherent_#{intervention.adherent_id}"
    assert_includes channels, "interventions_user_#{users(:bond).id}"
  end

  test 'broadcast_channels : intervention sans adhérent → aucun canal adhérent' do
    intervention = interventions(:tonte_locaux)
    intervention.update_columns(adherent_id: nil)

    assert_empty intervention.send(:broadcast_channels).grep(/adherent/)
  end

  private

  def intervention_sans_dates(adherent:, service:)
    Intervention.new(description: 'Contrôle du service', adherent: adherent, service: service)
  end

  def intervention_avec_photos
    Intervention.create!(description: 'Photo test',
                         adherent_id: users(:weil).id,
                         service: services(:informatique),
                         début_prévue: 1.day.from_now,
                         fin_prévue: 1.day.from_now + 1.hour)
  end

  def create_intervention_conventionnee(heures: 3, **attrs)
    début = attrs.delete(:début) || 10.hours.ago
    Intervention.create!({ description: 'intervention conventionnée',
                           adherent_id: users(:weil).id,
                           service: services(:informatique),
                           agents: [users(:hidalgo)],
                           temps_de_pause: 0,
                           début: début,
                           fin: début + heures.hours }.merge(attrs))
  end

  def png
    fixture_file_upload('exemple.png', 'image/png')
  end

  def cree_pointage_termine_par(agent)
    mère = interventions(:intervention_repete)
    pointage = mère.create_next_intervention(mère, agent)
    pointage.fin = Time.current
    pointage
  end
end
