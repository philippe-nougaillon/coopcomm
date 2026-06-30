# frozen_string_literal: true

require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
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
end
