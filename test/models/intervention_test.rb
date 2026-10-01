# frozen_string_literal: true

require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  # Un attachement n'étant pas une colonne, audited n'écrit une ligne que si le
  # commentaire est renseigné : c'est ce commentaire qui fait exister l'audit.
  test 'une photo ajoutée est auditée avec un libellé au singulier' do
    intervention = intervention_avec_photos

    assert_difference -> { intervention.audits.count }, 1 do
      intervention.update!(photos: [png])
    end
    assert_match(/1 photo ajoutée/i, intervention.audits.last.comment)
  end

  test 'deux photos ajoutées sont auditées avec un libellé au pluriel' do
    intervention = intervention_avec_photos
    intervention.update!(photos: [png])

    intervention.update!(photos: intervention.photos.map(&:signed_id) + [png, png])

    assert_match(/2 photos ajoutées/i, intervention.audits.last.comment)
  end

  test 'une photo existante ré-émise par le formulaire n’est pas auditée comme un ajout' do
    intervention = intervention_avec_photos
    intervention.update!(photos: [png])
    existante = intervention.photos.first

    intervention.update!(description: 'Titre modifié', photos: [existante.signed_id])

    assert_equal 1, intervention.reload.photos.count
    refute_match(/ajoutée/i, intervention.audits.last.comment.to_s)
  end

  # C'est la clé qui fait foi, pas l'association : User porte un default_scope
  # :kept, donc `adherent` rend nil dès que le compte est désactivé.
  test 'une intervention reste valide lorsque son adhérent est désactivé après avoir été rattaché' do
    adherent = users(:weil)
    intervention = intervention_sans_dates(adherent: adherent, service: services(:informatique))
    adherent.discard

    assert_nil intervention.reload_adherent
    assert_predicate intervention, :valid?
  end

  test 'une intervention existante dont l’adhérent est désactivé reste enregistrable' do
    intervention = interventions(:tonte_locaux)
    intervention.adherent.discard

    intervention.reload

    assert_nil intervention.adherent
    assert_predicate intervention.adherent_id, :present?
    assert_predicate intervention, :valid?
  end

  test 'les quatre dates d’une intervention sont enregistrées telles que fournies' do
    intervention = interventions(:nouvelle_intervention)
    début = Time.zone.local(2024, 4, 19, 9, 5, 37)
    fin = Time.zone.local(2024, 4, 19, 18, 45, 12)
    début_prévue = Time.zone.local(2030, 5, 4, 8, 15, 3)
    fin_prévue = Time.zone.local(2030, 5, 4, 17, 45, 59)

    intervention.update!(début: début, fin: fin, début_prévue: début_prévue, fin_prévue: fin_prévue)

    intervention.reload
    assert_equal début, intervention.début
    assert_equal fin, intervention.fin
    assert_equal début_prévue, intervention.début_prévue
    assert_equal fin_prévue, intervention.fin_prévue
  end

  test 'une intervention créée sans description reçoit son identifiant comme description' do
    intervention = Intervention.create!(description: '', adherent: users(:weil), service: services(:informatique))

    assert_equal "##{intervention.id}", intervention.reload.description
  end

  test 'une intervention créée avec une description la conserve' do
    intervention = Intervention.create!(description: 'Réparer la porte', adherent: users(:weil),
                                        service: services(:informatique))

    assert_equal 'Réparer la porte', intervention.reload.description
  end

  test 'une intervention encore liée à un mouvement ne peut pas être supprimée' do
    intervention = interventions(:tonte_locaux)
    Mouvement.create!(tool: tools(:tondeuse), user: users(:bond), intervention: intervention,
                      état: :réservé, date: Time.zone.parse('2026-06-02 09:00'))

    assert_not intervention.destroy
    assert_includes intervention.errors.full_messages, 'Il reste des mouvements liés.'
    assert Intervention.exists?(intervention.id)
  end

  test 'un modèle de pointage qui cesse de se répéter repasse à l’état nouveau' do
    intervention = interventions(:intervention_repete)
    intervention.update_columns(workflow_state: 'pointage activé')

    intervention.repeter = false
    intervention.valid?

    assert_equal 'nouveau', intervention.workflow_state
  end

  test 'une intervention qui devient un modèle de pointage passe à l’état pointage activé' do
    intervention = interventions(:nouvelle_intervention)

    intervention.repeter = true
    intervention.valid?

    assert_equal 'pointage activé', intervention.workflow_state
  end

  test 'une intervention terminée sans date de début est refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, début: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'une intervention terminée sans date de fin est refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, fin: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'une intervention terminée avec ses deux dates est acceptée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention, :valid?
  end

  test 'une intervention non terminée est acceptée sans dates' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: nil, fin: nil)

    assert_predicate intervention, :valid?
  end

  test 'une intervention terminée sans agent est refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all
    intervention.reload.workflow_state = Intervention::TERMINE

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join,
                    "Au moins un agent est obligatoire pour terminer l'intervention"
  end

  test 'une intervention terminée avec un agent est acceptée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention.agents, :any?
    assert_predicate intervention, :valid?
  end

  test 'une intervention non terminée est acceptée sans agent' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all

    assert_predicate intervention.reload, :valid?
  end

  test 'une intervention déjà terminée privée de ses agents n’est plus enregistrable' do
    intervention = interventions(:intervention_terminée)
    intervention.agents.destroy_all

    assert_not intervention.reload.update(commentaires: 'peu importe')
  end

  test 'le retrait de tous les agents d’une intervention terminée est refusé' do
    intervention = interventions(:intervention_terminée)
    intervention.agent_ids = []

    assert_not intervention.valid?
  end

  # Seuls les administrateurs échappent à la règle côté agents.

  test 'un adhérent étranger au service de l’intervention est refusé' do
    intervention = intervention_sans_dates(adherent: users(:berthout), service: services(:informatique))

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'adhérent #{users(:berthout).nom_prénom} n'appartient pas au service Informatique"
  end

  test 'un adhérent du service de l’intervention est accepté' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:informatique))

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'un agent étranger au service de l’intervention est refusé' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:john_wick)]

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{users(:john_wick).nom_prénom} n'appartient pas au service Technique"
  end

  test 'un agent du service de l’intervention est accepté' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:martin_technique_paris)]

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'un administrateur est accepté comme agent quel que soit son service' do
    admin = users(:philippe_super_admin)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [admin]

    assert_not_includes admin.service_ids, services(:technique).id
    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'un manager étranger au service de l’intervention est refusé comme agent, sans exemption' do
    manager = users(:manager_paris)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [manager]

    assert_not_includes manager.service_ids, services(:technique).id
    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{manager.nom_prénom} n'appartient pas au service Technique"
  end

  test 'un service étranger à l’adhérent comme aux agents est refusé des deux côtés' do
    intervention = interventions(:tonte_locaux)
    intervention.service = services(:secretariat)

    assert_not intervention.valid?
    assert_equal 2, intervention.errors.full_messages.count { |m| m.include?('Secrétariat') }
  end

  # Le créateur est déduit de l'audit de création : au niveau modèle, il faut `as_user`
  # pour le poser (dans l'app, `audited` capte le current_user du contrôleur).

  test 'aucun manager n’est notifié lorsqu’un agent crée une intervention non terminée' do
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

  test 'aucun manager n’est notifié lorsqu’une intervention est créée sans auteur connu' do
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

  test 'la terminaison d’une intervention ordinaire notifie les managers et l’adhérent' do
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.terminer! }
      end
    end
  end

  test 'la terminaison d’un pointage notifie les managers et l’adhérent' do
    pointage = cree_pointage_termine_par(users(:martin_technique_paris))

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { pointage.terminer! }
      end
    end
  end

  test 'une modification sans changement d’état ne notifie ni les managers ni l’adhérent' do
    intervention = interventions(:intervention_terminée)

    assert_no_enqueued_jobs only: [NotifManagersWorkflowChangedJob, NotifAdherentInterventionTermineeJob] do
      Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.update!(commentaires: 'Relu') }
    end
  end

  test 'la liste ordonnée des interventions place la plus récemment mise à jour en tête' do
    récente = interventions(:nouvelle_intervention)
    récente.update_columns(updated_at: 1.minute.from_now)

    assert_equal récente, Intervention.ordered.first
  end

  test 'les interventions courantes sont celles aux états nouveau, pointage activé et terminé' do
    états = Intervention.courantes.pluck(:workflow_state).uniq

    assert_includes états, 'nouveau'
    assert_not_includes états, 'validé'
    assert_not_includes états, 'archivé'
  end

  test 'le filtre par service ne retourne que les interventions de ces services' do
    filtrées = Intervention.filter_by_service([services(:technique)])

    assert filtrées.all? { |i| i.service_id == services(:technique).id }
    assert_includes filtrées, interventions(:tonte_locaux)
  end

  test 'la liste des interventions d’un manager contient toutes les interventions' do
    listées = Intervention.by_role_for(users(:hidalgo))

    assert_includes listées, interventions(:tonte_locaux)
    assert_includes listées, interventions(:intervention_autre_adhérent)
  end

  test 'la liste des interventions d’un adhérent ne contient que les siennes' do
    listées = Intervention.by_role_for(users(:weil))

    assert listées.all? { |i| i.adherent_id == users(:weil).id }
  end

  test 'la liste des interventions d’un agent ne contient que celles où il est affecté' do
    agent = users(:martin_technique_paris)

    listées = Intervention.by_role_for(agent)

    assert listées.all? { |i| i.agents.include?(agent) }
    assert_not_includes listées, interventions(:intervention_with_location)
  end

  test 'les dates effectives sont les dates réelles lorsqu’elles sont renseignées' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: Time.zone.local(2030, 5, 4, 9), fin: Time.zone.local(2030, 5, 4, 11),
                                   début_prévue: Time.zone.local(2030, 5, 4, 14),
                                   fin_prévue: Time.zone.local(2030, 5, 4, 16))

    assert_equal Time.zone.local(2030, 5, 4, 9), intervention.effective_début
    assert_equal Time.zone.local(2030, 5, 4, 11), intervention.effective_fin
  end

  test 'les dates effectives se replient sur les dates prévues lorsque les réelles manquent' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: nil, fin: nil,
                                   début_prévue: Time.zone.local(2030, 5, 4, 14),
                                   fin_prévue: Time.zone.local(2030, 5, 4, 16))

    assert_equal Time.zone.local(2030, 5, 4, 14), intervention.effective_début
    assert_equal Time.zone.local(2030, 5, 4, 16), intervention.effective_fin
  end

  test 'une fille de pointage sans fin est un pointage ouvert' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert fille.pointage_ouvert?
  end

  test 'une fille de pointage clôturée n’est pas un pointage ouvert' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))
    fille.update_columns(fin: Time.current)

    assert_not fille.reload.pointage_ouvert?
  end

  test 'une intervention hors pointage n’est pas un pointage ouvert' do
    assert_not interventions(:nouvelle_intervention).pointage_ouvert?
  end

  test 'la durée d’une intervention est affichée en heures, minutes et secondes' do
    intervention = interventions(:nouvelle_intervention)
    intervention.début = Time.zone.local(2030, 5, 4, 9, 0)
    intervention.fin = Time.zone.local(2030, 5, 4, 11, 30, 12)

    assert_equal '02h 30min 12sec', intervention.durée_humanized
  end

  test 'les dates d’un pointage sont affichées avec les secondes' do
    mère = interventions(:intervention_repete)
    fille = mère.create_next_intervention(mère, users(:martin_technique_paris))

    assert_equal :very_long, fille.format_date
  end

  test 'les dates d’une intervention ordinaire sont affichées sans les secondes' do
    assert_equal :long, interventions(:nouvelle_intervention).format_date
  end

  test 'le format réservé aux pointages affiche réellement les secondes' do
    horaire = Time.zone.local(2030, 5, 4, 9, 0, 12)

    assert_includes I18n.l(horaire, format: :very_long), '12s'
    assert_not_includes I18n.l(horaire, format: :long), '12s'
  end

  test 'une intervention à l’état nouveau dont la fin n’est pas atteinte n’est pas passée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.fin = 1.hour.from_now

    assert_not intervention.passed
  end

  test 'une intervention à l’état nouveau dont la fin est dépassée est passée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.fin = 1.hour.ago

    assert intervention.passed
  end

  test 'une intervention sortie de l’état nouveau est passée' do
    assert interventions(:tonte_locaux).passed
  end

  test 'le temps par agent divise le temps total entre les agents affectés' do
    intervention = interventions(:tonte_locaux)

    assert_in_delta intervention.temps_total / intervention.agents.count, intervention.temps_par_agent, 1e-6
  end

  test 'le temps par agent vaut le temps total entier lorsqu’aucun agent n’est affecté' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all

    assert_equal intervention.reload.temps_total, intervention.temps_par_agent
  end

  test 'une intervention créée par un agent est un bon d’intervention' do
    intervention = nil
    Audited.audit_class.as_user(users(:martin_technique_paris)) do
      intervention = Intervention.create!(description: 'Bon agent', adherent: users(:weil),
                                          service: services(:informatique))
    end

    assert intervention.bon?
  end

  test 'une intervention créée par un manager n’est pas un bon d’intervention' do
    intervention = nil
    Audited.audit_class.as_user(users(:hidalgo)) do
      intervention = Intervention.create!(description: 'Demande manager', adherent: users(:weil),
                                          service: services(:informatique))
    end

    assert_not intervention.bon?
  end

  test 'la couleur d’une intervention est celle déclarée sur son état' do
    assert_equal '0,181,255,255', interventions(:nouvelle_intervention).rgba
  end

  test 'le décompte par état d’un lot d’interventions compte chaque état, y compris à zéro' do
    comptes = Intervention.workflow_states_count(Intervention.where(id: interventions(:tonte_locaux).id))

    assert_equal 1, comptes['Validé']
    assert_equal 0, comptes['Nouveau']
    assert_equal Intervention.workflow_state_humanized.sort, comptes.keys.sort
  end

  # Côté agent le périmètre n'est pas restreint aux filles de pointage :
  # toutes ses interventions « nouveau » sont listées.

  test 'la page d’accueil d’un agent liste ses interventions ordinaires à l’état nouveau' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    assert_nil intervention.template_slug
    assert_includes intervention.agents, agent

    assert_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'la page d’accueil d’un agent liste ses filles de pointage à l’état nouveau' do
    agent = users(:martin_technique_paris)
    fille = interventions(:intervention_fille)
    fille.update_columns(template_slug: interventions(:intervention_repete).slug)

    assert_includes Intervention.by_role_for_home(agent), fille
  end

  test 'la page d’accueil d’un agent exclut ses interventions sorties de l’état nouveau' do
    listées = Intervention.by_role_for_home(users(:martin_technique_paris))

    assert_not_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:intervention_validé)
  end

  test 'la page d’accueil d’un agent exclut une intervention à l’état nouveau d’un autre agent' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:intervention_with_location)

    assert_equal 'nouveau', intervention.workflow_state
    assert_not_includes intervention.agents, agent

    assert_not_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'la page d’accueil d’un agent trie ses interventions par mise à jour décroissante' do
    agent = users(:martin_technique_paris)
    interventions(:intervention_paris).update_columns(updated_at: 1.minute.from_now)

    assert_equal interventions(:intervention_paris), Intervention.by_role_for_home(agent).first
  end

  test 'la page d’accueil d’un adhérent ne liste que ses interventions terminées' do
    listées = Intervention.by_role_for_home(users(:weil))

    assert_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:nouvelle_intervention)
    assert_not_includes listées, interventions(:intervention_autre_adhérent)
  end

  test 'la page d’accueil d’un manager exclut les interventions validées, refusées et archivées' do
    listées = Intervention.by_role_for_home(users(:hidalgo))

    assert_includes listées, interventions(:nouvelle_intervention)
    assert_includes listées, interventions(:intervention_terminée)
    assert_not_includes listées, interventions(:tonte_locaux)
  end

  test 'le QR code d’une intervention est rendu en SVG' do
    svg = interventions(:intervention_repete).qrcode('https://example.test/pointer')

    assert_includes svg, '<svg'
  end

  test 'la dernière intervention en cours est celle qui recouvre l’instant présent' do
    agent = users(:nettoyage)
    en_cours = Intervention.create!(
      description: 'En cours maintenant', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, Intervention.dernière_en_cours(agent.interventions)
  end

  test 'aucune dernière intervention en cours n’est retenue parmi des interventions sans date prévue' do
    assert_nil Intervention.dernière_en_cours(Intervention.where(id: interventions(:nouvelle_intervention).id))
  end

  test 'une intervention complète est diffusée à son organisation, son service, son adhérent et ses agents' do
    intervention = interventions(:tonte_locaux)

    channels = intervention.send(:broadcast_channels)

    assert_includes channels, "interventions_organisation_#{intervention.organisation.id}"
    assert_includes channels, "interventions_service_#{intervention.service_id}"
    assert_includes channels, "interventions_adherent_#{intervention.adherent_id}"
    assert_includes channels, "interventions_user_#{users(:bond).id}"
  end

  test 'une intervention sans adhérent n’est diffusée sur aucun canal adhérent' do
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
