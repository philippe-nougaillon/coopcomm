# frozen_string_literal: true

require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # --- Notification des managers à la création (send_manager_notification) ---
  # Le créateur est déduit de l'audit de création : au niveau modèle, il faut `as_user`
  # pour le poser (dans l'app, `audited` capte le current_user du contrôleur).

  test "création par un agent NON terminée : aucune notification managers n'est enqueue" do
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

  test "création sans utilisateur d'audit (système/console) : aucune notification managers n'est enqueue" do
    assert_no_enqueued_jobs only: [NotifManagersNewInterventionFromAdherentJob,
                                   NotifManagersInterventionDoneByAgentJob] do
      Intervention.create!(description: 'Création système',
                           adherent_id: users(:weil).id,
                           service: services(:informatique),
                           début_prévue: 1.day.from_now,
                           fin_prévue: 1.day.from_now + 1.hour)
    end
  end

  # --- broadcast_channels : périmètre des destinataires du live-update Turbo ---
  # Cf. l'abonnement par rôle dans interventions/index.html.erb.

  # test 'broadcast_channels cible organisation, service, adhérent et chaque agent' do
  #   intervention = interventions(:tonte_locaux)

  #   expected = [
  #     "interventions_organisation_#{intervention.organisation.id}",
  #     "interventions_service_#{intervention.service_id}",
  #     "interventions_adherent_#{intervention.adherent_id}"
  #   ] + intervention.agents.map { |a| "interventions_user_#{a.id}" }

  #   assert_equal expected.sort, intervention.send(:broadcast_channels).sort
  # end

  # test "broadcast_channels inclut le canal service correspondant aux services d'un manager" do
  #   intervention = interventions(:tonte_locaux)
  #   manager = users(:hidalgo) # manager rattaché au service technique

  #   assert_includes manager.service_ids, intervention.service_id,
  #                   'préalable : le manager doit avoir le service de l\'intervention'
  #   assert_includes intervention.send(:broadcast_channels),
  #                   "interventions_service_#{intervention.service_id}"
  # end

  # test 'broadcast_channels omet le canal adhérent quand adherent_id est absent' do
  #   intervention = interventions(:tonte_locaux)
  #   intervention.adherent_id = nil

  #   assert(intervention.send(:broadcast_channels).none? { |c| c.start_with?('interventions_adherent_') })
  # end

  # # --- Cas négatifs : qui ne doit PAS recevoir le live-update ---
  # # On reconstruit le canal auquel chaque non-destinataire s'abonne dans la vue
  # # (cf. interventions/index.html.erb) et on vérifie qu'il est absent de la diffusion.

  # test "broadcast_channels exclut un manager dont aucun service ne couvre l'intervention" do
  #   intervention = interventions(:tonte_locaux)
  #   manager = users(:manager_paris) # services service_paris + secretariat, pas technique
  #   channels = intervention.send(:broadcast_channels)

  #   assert_not_includes manager.service_ids, intervention.service_id,
  #                       'préalable : ce manager ne doit PAS avoir le service de l\'intervention'
  #   manager.service_ids.each do |service_id|
  #     assert_not_includes channels, "interventions_service_#{service_id}"
  #   end
  # end

  # test "broadcast_channels exclut le canal d'un adhérent non rattaché à l'intervention" do
  #   intervention = interventions(:tonte_locaux)
  #   autre_adherent = users(:berthout)

  #   assert_not_equal intervention.adherent_id, autre_adherent.id
  #   assert_not_includes intervention.send(:broadcast_channels),
  #                       "interventions_adherent_#{autre_adherent.id}"
  # end

  # test 'broadcast_channels exclut un agent du même service mais non assigné' do
  #   intervention = interventions(:tonte_locaux)
  #   agent_non_assigne = users(:nettoyage) # agent du service technique, non affecté à cette intervention

  #   assert_not_includes intervention.agents, agent_non_assigne,
  #                       'préalable : cet agent ne doit PAS être assigné à l\'intervention'
  #   assert_not_includes intervention.send(:broadcast_channels),
  #                       "interventions_user_#{agent_non_assigne.id}"
  # end

  # --- Heures consommées de la convention (update_heures_consommees_convention) ---
  # Remplace Convention#temps_total_interventions (tests déplacés depuis
  # convention_test.rb).

  # temps_total est dérivé des dates et du nombre d'agents, jamais fixé à la main.
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

  test "création : le temps_total s'ajoute aux heures consommées de la convention couvrant l'intervention" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 3)
      create_intervention_conventionnee(heures: 5, début: 6.hours.ago)

      assert_equal 8, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention d'un autre service ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, service: services(:technique))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention d'un autre adhérent ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, adherent_id: users(:adhérent_sans_intervention).id)

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention hors période de la convention ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(heures: 4, début: Time.zone.parse('2025-06-01 06:00:00'))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "modification du temps_total : seule la différence s'ajoute aux heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)
      intervention.update!(fin: intervention.début + 5.hours)

      assert_equal 5, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'modification sans changement du temps_total : heures consommées inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)
      intervention.update!(description: 'description modifiée')

      assert_equal 3, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'suppression : le temps_total est retranché des heures consommées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(heures: 3)
      intervention.destroy!

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  # --- by_role_for_home : ce que chaque rôle voit sur /home ---
  # Côté agent le périmètre n'est plus restreint aux filles de pointage :
  # toutes ses interventions « nouveau » sont listées.

  test 'home agent : une intervention ordinaire à l\'état nouveau est listée' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    assert_nil intervention.template_slug
    assert_includes intervention.agents, agent

    assert_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'home agent : une fille de pointage à l\'état nouveau reste listée' do
    agent = users(:martin_technique_paris)
    fille = interventions(:intervention_fille)
    fille.update_columns(template_slug: interventions(:intervention_repete).slug)

    assert_includes Intervention.by_role_for_home(agent), fille
  end

  test 'home agent : les interventions qui ont quitté l\'état nouveau sont exclues' do
    listees = Intervention.by_role_for_home(users(:martin_technique_paris))

    assert_not_includes listees, interventions(:intervention_terminée)
    assert_not_includes listees, interventions(:intervention_validé)
  end

  test 'home agent : l\'intervention nouveau d\'un autre agent est exclue' do
    agent = users(:martin_technique_paris)
    intervention = interventions(:intervention_with_location)

    assert_equal 'nouveau', intervention.workflow_state
    assert_not_includes intervention.agents, agent

    assert_not_includes Intervention.by_role_for_home(agent), intervention
  end

  test 'home agent : les interventions sont triées par mise à jour décroissante' do
    agent = users(:martin_technique_paris)
    interventions(:intervention_paris).update_columns(updated_at: 1.minute.from_now)

    assert_equal interventions(:intervention_paris), Intervention.by_role_for_home(agent).first
  end

  test 'home adhérent : seules ses interventions terminées sont listées' do
    listees = Intervention.by_role_for_home(users(:weil))

    assert_includes listees, interventions(:intervention_terminée)
    assert_not_includes listees, interventions(:nouvelle_intervention)
    assert_not_includes listees, interventions(:intervention_autre_adhérent)
  end

  test 'home manager : les interventions validées, refusées et archivées sont exclues' do
    listees = Intervention.by_role_for_home(users(:hidalgo))

    assert_includes listees, interventions(:nouvelle_intervention)
    assert_includes listees, interventions(:intervention_terminée)
    assert_not_includes listees, interventions(:tonte_locaux)
  end

  # --- Présentation : couleur, comptage par état, QRCode ---

  test 'rgba expose la couleur déclarée sur l\'état courant' do
    assert_equal '0,181,255,255', interventions(:nouvelle_intervention).rgba
  end

  test 'workflow_states_count compte chaque état, y compris ceux à zéro' do
    comptes = Intervention.workflow_states_count(Intervention.where(id: interventions(:tonte_locaux).id))

    assert_equal 1, comptes['Validé']
    assert_equal 0, comptes['Nouveau']
    assert_equal Intervention.workflow_state_humanized.sort, comptes.keys.sort
  end

  test 'qrcode produit un SVG à partir de l\'URL fournie' do
    svg = interventions(:intervention_repete).qrcode('https://example.test/pointer')

    assert_includes svg, '<svg'
  end

  # --- dernière_en_cours ---

  test 'dernière_en_cours retient l\'intervention qui recouvre l\'instant présent' do
    agent = users(:nettoyage)
    en_cours = Intervention.create!(
      description: 'En cours maintenant', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, Intervention.dernière_en_cours(agent.interventions)
  end

  test 'dernière_en_cours ignore les interventions sans date prévue' do
    assert_nil Intervention.dernière_en_cours(Intervention.where(id: interventions(:nouvelle_intervention).id))
  end

  # --- extract_temps_total_depending_on_audit ---

  test 'un audit sans variation de temps total ne compte pour rien' do
    intervention = interventions(:tonte_locaux)
    audit = intervention.audits.build(action: 'update', audited_changes: { 'description' => %w[avant après] })

    assert_equal 0, intervention.send(:extract_temps_total_depending_on_audit, audit)
  end

  test 'un audit de création ajoute le temps total enregistré' do
    intervention = interventions(:tonte_locaux)
    audit = intervention.audits.build(action: 'create', audited_changes: { 'temps_total' => 5 })

    assert_equal 5, intervention.send(:extract_temps_total_depending_on_audit, audit)
  end

  # --- Diffusion temps réel (callback actuellement commenté) ---

  test 'broadcast_channels couvre l\'organisation, le service, l\'adhérent et les agents' do
    intervention = interventions(:tonte_locaux)

    channels = intervention.send(:broadcast_channels)

    assert_includes channels, "interventions_organisation_#{intervention.organisation.id}"
    assert_includes channels, "interventions_service_#{intervention.service_id}"
    assert_includes channels, "interventions_adherent_#{intervention.adherent_id}"
    assert_includes channels, "interventions_user_#{users(:bond).id}"
  end

  test 'broadcast_channels n\'ajoute pas de canal adhérent quand il n\'y en a pas' do
    intervention = interventions(:tonte_locaux)
    intervention.update_columns(adherent_id: nil)

    assert_empty intervention.send(:broadcast_channels).grep(/adherent/)
  end

  # --- État « pointage activé » tenu à jour ---

  test 'un modèle de pointage qui cesse de se répéter repasse à nouveau' do
    intervention = interventions(:intervention_repete)
    intervention.update_columns(workflow_state: 'pointage activé')

    intervention.repeter = false
    intervention.valid?

    assert_equal 'nouveau', intervention.workflow_state
  end

  test 'une intervention qui devient un modèle passe à pointage activé' do
    intervention = interventions(:nouvelle_intervention)

    intervention.repeter = true
    intervention.valid?

    assert_equal 'pointage activé', intervention.workflow_state
  end

  # --- Passage à l'état terminé : dates obligatoires et événements publiés ---

  test 'terminé sans date de début : invalide' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, début: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'terminé sans date de fin : invalide' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(workflow_state: Intervention::TERMINE, fin: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, 'obligatoire pour terminer'
  end

  test 'terminé avec les deux dates : valide' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention, :valid?
  end

  test 'un état autre que terminé n’exige pas les dates' do
    intervention = interventions(:nouvelle_intervention)
    intervention.assign_attributes(début: nil, fin: nil)

    assert_predicate intervention, :valid?
  end

  test 'terminé sans agent : invalide' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all
    intervention.reload.workflow_state = Intervention::TERMINE

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join, "Au moins un agent est obligatoire pour terminer l'intervention"
  end

  test 'terminé avec un agent : valide' do
    intervention = interventions(:nouvelle_intervention)
    intervention.workflow_state = Intervention::TERMINE

    assert_predicate intervention.agents, :any?
    assert_predicate intervention, :valid?
  end

  test 'un état autre que terminé n’exige pas d’agent' do
    intervention = interventions(:nouvelle_intervention)
    intervention.agents.destroy_all

    assert_predicate intervention.reload, :valid?
  end

  test 'une intervention déjà terminée sans agent ne peut plus être enregistrée' do
    intervention = interventions(:intervention_terminée)
    intervention.agents.destroy_all

    assert_not intervention.reload.update(commentaires: 'peu importe')
  end

  test 'agents retirés d’une intervention terminée : invalide' do
    intervention = interventions(:intervention_terminée)
    intervention.agent_ids = []

    assert_not intervention.valid?
  end

  # Les événements sont observés par les jobs qu'ils déclenchent : les mêmes
  # sondes que test/subscription.
  test 'terminer publie workflow_changed et done' do
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.terminer! }
      end
    end
  end

  test 'terminer un pointage ne publie pas done' do
    pointage = cree_pointage_termine_par(users(:martin_technique_paris))

    assert_no_enqueued_jobs only: NotifAdherentInterventionTermineeJob do
      assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
        Audited.audit_class.as_user(users(:martin_technique_paris)) { pointage.terminer! }
      end
    end
  end

  test 'sans_notification : la terminaison ne publie aucun événement' do
    intervention = interventions(:nouvelle_intervention)
    intervention.sans_notification = true

    assert_no_enqueued_jobs only: [NotifManagersWorkflowChangedJob, NotifAdherentInterventionTermineeJob] do
      Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.terminer! }
    end
  end

  test 'une modification sans changement d’état ne publie rien' do
    intervention = interventions(:intervention_terminée)

    assert_no_enqueued_jobs only: [NotifManagersWorkflowChangedJob, NotifAdherentInterventionTermineeJob] do
      Audited.audit_class.as_user(users(:martin_technique_paris)) { intervention.update!(commentaires: 'Relu') }
    end
  end

  # === Le service doit être partagé par l'adhérent et les agents ============
  # Seuls les administrateurs échappent à la règle côté agents.

  test "un adhérent qui n'appartient pas au service de l'intervention est refusé" do
    intervention = intervention_sans_dates(adherent: users(:berthout), service: services(:informatique))

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'adhérent #{users(:berthout).nom_prénom} n'appartient pas au service Informatique"
  end

  test "un adhérent qui appartient au service de l'intervention est accepté" do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:informatique))

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test "un agent qui n'appartient pas au service de l'intervention est refusé" do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:john_wick)]

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{users(:john_wick).nom_prénom} n'appartient pas au service Technique"
  end

  test "un agent qui appartient au service de l'intervention est accepté" do
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [users(:martin_technique_paris)]

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test "un administrateur est accepté comme agent quel que soit son service" do
    admin = users(:philippe_super_admin)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [admin]

    assert_not_includes admin.service_ids, services(:technique).id
    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test "un manager n'est pas exempté : hors service, il est refusé comme agent" do
    manager = users(:manager_paris)
    intervention = intervention_sans_dates(adherent: users(:weil), service: services(:technique))
    intervention.agents = [manager]

    assert_not_includes manager.service_ids, services(:technique).id
    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages,
                    "L'agent #{manager.nom_prénom} n'appartient pas au service Technique"
  end

  test 'changer le service pour un service étranger à tout le monde est refusé' do
    intervention = interventions(:tonte_locaux)
    intervention.service = services(:secretariat)

    assert_not intervention.valid?
    assert_equal 2, intervention.errors.full_messages.count { |m| m.include?('Secrétariat') }
  end

  # Sans `dependent: :destroy` sur la through, Rails retire la ligne de liaison
  # par delete_all : aucun callback, donc aucune trace de l'outil retiré.
  test 'retirer un outil à une intervention laisse une trace dans l\'audit' do
    intervention = interventions(:tonte_locaux)
    intervention.update!(tool_ids: [tools(:tondeuse).id])

    assert_difference -> { Audited::Audit.where(auditable_type: 'ToolIntervention', action: 'destroy').count }, 1 do
      intervention.update!(tool_ids: [])
    end

    audit = Audited::Audit.where(auditable_type: 'ToolIntervention', action: 'destroy').last

    assert_equal tools(:tondeuse).id, audit.audited_changes['tool_id']
    assert_equal intervention.id, audit.associated_id
  end

  # === Service et adhérent obligatoires =====================================

  test 'une intervention sans service est refusée' do
    intervention = intervention_sans_dates(adherent: users(:weil), service: nil)

    assert_not intervention.valid?
    assert_includes intervention.errors.attribute_names, :service_id
  end

  test 'une intervention sans adhérent est refusée' do
    intervention = intervention_sans_dates(adherent: nil, service: services(:informatique))

    assert_not intervention.valid?
    assert_includes intervention.errors.attribute_names, :adherent_id
  end

  # C'est la clé qui fait foi, pas l'association : User porte un default_scope
  # :kept, donc `adherent` rend nil dès que le compte est désactivé.
  test 'un adhérent désactivé reste un adhérent valide à la création' do
    adherent = users(:weil)
    intervention = intervention_sans_dates(adherent: adherent, service: services(:informatique))
    adherent.discard

    assert_nil intervention.reload_adherent
    assert_predicate intervention, :valid?
  end

  test 'une intervention dont l’adhérent est désactivé reste enregistrable' do
    intervention = interventions(:tonte_locaux)
    intervention.adherent.discard

    intervention.reload

    assert_nil intervention.adherent
    assert_predicate intervention.adherent_id, :present?
    assert_predicate intervention, :valid?
  end

  private

  def intervention_sans_dates(adherent:, service:)
    Intervention.new(description: 'Contrôle du service', adherent: adherent, service: service)
  end

  def cree_pointage_termine_par(agent)
    mère = interventions(:intervention_repete)
    pointage = mère.create_next_intervention(mère, agent)
    pointage.fin = Time.current
    pointage
  end
end
