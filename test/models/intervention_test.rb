# frozen_string_literal: true

require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # --- Notification des managers à la création (send_manager_notification) ---
  # Le créateur est déduit de l'audit de création : au niveau modèle, il faut
  # `as_user` pour le poser (dans l'app, `audited` capte le current_user du contrôleur).

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
  # Remplace Convention#temps_total_interventions (tests déplacés depuis convention_test.rb).
  # Le cumul est entretenu incrémentalement par un after_commit, à partir du dernier
  # audit de l'intervention : création → + temps_total ; update → + (nouveau − ancien) ;
  # destroy → − temps_total. Convention de fixture : convention_paris (weil / informatique,
  # année 2026, heures_consommees: 0). Ancrage temporel fixe (travel_to) pour rester
  # dans la période de la convention quelle que soit la date d'exécution.
  # NB : temps_total est assigné explicitement — le before_save calc_temps_total est
  # aujourd'hui inopérant (bug B1 du registre) ; s'il est corrigé, prévoir début/fin/agents
  # cohérents avec la valeur attendue.

  def create_intervention_conventionnee(attrs = {})
    Intervention.create!({ description: 'intervention conventionnée',
                           adherent_id: users(:weil).id,
                           service: services(:informatique),
                           début: 2.hours.ago }.merge(attrs))
  end

  test "création : le temps_total s'ajoute aux heures consommées de la convention couvrant l'intervention" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(temps_total: 3)
      create_intervention_conventionnee(temps_total: 5)

      assert_equal 8, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention d'un autre service ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(temps_total: 99, service: services(:service_marseille))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention d'un autre adhérent ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(temps_total: 99, adherent_id: users(:michael_jackson).id)

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "création : une intervention hors période de la convention ne modifie pas les heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      create_intervention_conventionnee(temps_total: 99, début: Time.zone.parse('2025-06-01 12:00:00'))

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test "modification du temps_total : seule la différence s'ajoute aux heures consommées" do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(temps_total: 3)
      intervention.update!(temps_total: 5)

      assert_equal 5, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'modification sans changement du temps_total : heures consommées inchangées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(temps_total: 3)
      intervention.update!(description: 'description modifiée')

      assert_equal 3, conventions(:convention_paris).reload.heures_consommees
    end
  end

  test 'suppression : le temps_total est retranché des heures consommées' do
    travel_to Time.zone.parse('2026-06-01 12:00:00') do
      intervention = create_intervention_conventionnee(temps_total: 3)
      intervention.destroy!

      assert_equal 0, conventions(:convention_paris).reload.heures_consommees
    end
  end
end
