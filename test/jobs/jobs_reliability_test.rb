# frozen_string_literal: true

require 'test_helper'

# Tests transverses de fiabilité des jobs (au-delà du « chemin nominal » couvert job par
# job) : sérialisation des arguments et idempotence au rejeu (retry).
class JobsReliabilityTest < ActiveJob::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  # --- ANGLE 1a : argument SUPPRIMÉ (hard delete) ----------------------------
  # Les jobs reçoivent des objets ActiveRecord sérialisés via GlobalID.

  test 'un argument détruit entre l\'enqueue et l\'exécution lève DeserializationError' do
    # Intervention non référencée par des enfants (agent/tool/mouvement) → suppression nette.
    intervention = interventions(:intervention_sans_manager)
    # On fige la charge enqueue-ée (arguments → GlobalID) puis on supprime
    # l'enregistrement, comme le ferait une suppression survenue avant que le worker ne
    serialized = NotifMailAdherentInterventionPointageJob.new(intervention).serialize
    intervention.delete # suppression SQL directe : la ligne n'est plus en base

    assert_no_emails do
      assert_raises(ActiveJob::DeserializationError) do
        ActiveJob::Base.deserialize(serialized).perform_now
      end
    end
  end

  # --- ANGLE 1b : argument SOFT-DELETED (discard) ----------------------------
  # Piège subtil : User/Commande/Cotation sont *discardables* (default_scope :kept).

  test 'un argument User soft-deleted (discard) N\'est PAS attrapé à la désérialisation (GlobalID ignore default_scope :kept)' do
    adherent = users(:weil)
    gid = adherent.to_global_id.to_s
    adherent.discard

    assert adherent.reload.discarded?, 'pré-condition : adhérent discardé'
    # User.find l'exclut (kept scope)…
    assert_raises(ActiveRecord::RecordNotFound) { User.find(adherent.id) }
    # …mais GlobalID le retrouve malgré tout → aucune DeserializationError
    # possible, donc discard_on n'offrirait aucune protection ici.
    assert_equal adherent.id, GlobalID::Locator.locate(gid).id
  end

  # --- ANGLE 3 : idempotence / rejeu (retry) ---------------------------------
  # Aucun de ces jobs n'est idempotent : ils n'ont pas de clé de déduplication.

  test 'rejouer un job de notification double ses effets (mail + MailLog)' do
    intervention = interventions(:tonte_locaux)
    adherent     = users(:weil)
    user_id      = users(:administrateur_paris).id

    assert_difference [-> { ActionMailer::Base.deliveries.size }, -> { MailLog.count }], 2 do
      2.times do
        NotifAdherentInterventionTermineeJob.perform_now(intervention, adherent, user_id)
      end
    end
  end
end
