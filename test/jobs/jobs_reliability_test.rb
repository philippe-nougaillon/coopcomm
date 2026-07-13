# frozen_string_literal: true

require 'test_helper'

# Tests transverses de fiabilité des jobs (au-delà du « chemin nominal » couvert
# job par job) : sérialisation des arguments et idempotence au rejeu (retry).
# Ces deux angles sont ceux qui cassent réellement en production, car les jobs
# sont enqueue-és (perform_later) puis exécutés plus tard, éventuellement rejoués.
class JobsReliabilityTest < ActiveJob::TestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  # --- ANGLE 1a : argument SUPPRIMÉ (hard delete) ----------------------------
  # Les jobs reçoivent des objets ActiveRecord sérialisés via GlobalID. Si
  # l'enregistrement est réellement détruit entre l'enqueue et l'exécution, la
  # DÉSÉRIALISATION échoue. `ApplicationJob` a `discard_on
  # ActiveJob::DeserializationError` COMMENTÉ → le job lève et sera rejoué par
  # Solid Queue au lieu d'être abandonné proprement.

  test 'un argument détruit entre l\'enqueue et l\'exécution lève DeserializationError' do
    # Intervention non référencée par des enfants (agent/tool/mouvement) → suppression nette.
    intervention = interventions(:intervention_sans_manager)
    # On fige la charge enqueue-ée (arguments → GlobalID) puis on supprime
    # l'enregistrement, comme le ferait une suppression survenue avant que le
    # worker ne dépile le job. Approche indépendante de l'adaptateur de queue.
    serialized = NotifMailAdherentInterventionPointageJob.new(intervention).serialize
    intervention.delete # suppression SQL directe : la ligne n'est plus en base

    assert_no_emails do
      assert_raises(ActiveJob::DeserializationError) do
        ActiveJob::Base.deserialize(serialized).perform_now
      end
    end
  end

  # --- ANGLE 1b : argument SOFT-DELETED (discard) ----------------------------
  # Piège subtil : User/Commande/Cotation sont *discardables* (default_scope
  # :kept). On pourrait croire qu'un `discard_on DeserializationError`
  # protègerait. Il n'en est RIEN : GlobalID::Locator IGNORE le default_scope
  # et localise quand même l'enregistrement discardé. Le job s'exécute donc avec
  # un enregistrement « zombie » — et échoue plus loin (rendu du mailer,
  # associations kept-scopées à nil), pas à la désérialisation.

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
  # Un rejeu (retry Solid Queue après une erreur transitoire, ou double enqueue)
  # REPRODUIT tous les effets. Ceci CONFIRME le risque « mails en double »
  # évoqué pour les jobs qui crashaient après l'envoi du mail.

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
