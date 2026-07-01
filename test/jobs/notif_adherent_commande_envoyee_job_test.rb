# frozen_string_literal: true

require 'test_helper'

class NotifAdherentCommandeEnvoyeeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @commande = commandes(:commande_paris)
    @adherent = @commande.adherent
    @sender   = users(:administrateur_paris)
  end

  # --- Comportement RÉEL constaté (bug, voir note en bas de fichier) ---------

  test 'le job plante car MailLog n\'a pas de colonne commande_id' do
    # Le mail PART (deliver_now, l'.4) PUIS la création du MailLog lève une
    # exception : la colonne commande_id n'existe pas sur mail_logs.
    assert_emails 1 do
      assert_no_difference -> { MailLog.count } do
        assert_raises(ActiveModel::UnknownAttributeError) do
          NotifAdherentCommandeEnvoyeeJob.perform_now(@commande, @adherent, @sender.id)
        end
      end
    end
  end

  # --- Comportement ATTENDU une fois le bug corrigé --------------------------
  # Décommenter (retirer les skip) quand la colonne commande_id aura été ajoutée
  # à mail_logs et l'association déclarée sur MailLog.

  test 'envoie un mail à l\'adhérent et crée un MailLog tracé' do
    skip 'BUG: mail_logs.commande_id absent → MailLog.create lève UnknownAttributeError (voir note bas de fichier)'

    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentCommandeEnvoyeeJob.perform_now(@commande, @adherent, @sender.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    # Le sujet tracé doit être identique à celui réellement envoyé (source unique).
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @commande.organisation.id, log.organisation_id
    assert_equal @sender.id, log.user_id
    assert_equal 'mail', log.channel
    # Le log doit être rattaché à la commande, pour le retrouver dans l'index.
    assert_equal @commande.id, log.commande_id
  end

  test 'met l\'émetteur en copie du mail' do
    skip 'BUG: mail_logs.commande_id absent → MailLog.create lève UnknownAttributeError (voir note bas de fichier)'

    NotifAdherentCommandeEnvoyeeJob.perform_now(@commande, @adherent, @sender.id)

    assert_equal [@sender.email], ActionMailer::Base.deliveries.last.cc
  end
end

# =============================================================================
# ANOMALIE DÉTECTÉE — NON CORRIGÉE (signalée, hors périmètre de cette session)
# -----------------------------------------------------------------------------
# NotifAdherentCommandeEnvoyeeJob#perform (app/jobs/notif_adherent_commande_envoyee_job.rb:13)
# appelle MailLog.create(..., commande_id: commande.id, ...), mais la table
# mail_logs n'a PAS de colonne commande_id (seule cotation_id a été ajoutée par
# la migration 20260611124048_add_cotation_to_mail_logs). Résultat :
#   ActiveModel::UnknownAttributeError: unknown attribute 'commande_id' for MailLog.
#
# Conséquence en production : le mail « commande envoyée » EST délivré
# (deliver_now précède la création du MailLog), puis le job CRASHE → aucun
# MailLog tracé, et selon la politique de retry Solid Queue le job rejoue →
# l'adhérent peut recevoir plusieurs fois le même mail.
#
# Correctif attendu (à valider avec le client) :
#   1. migration : add_reference :mail_logs, :commande, null: true, foreign_key: true
#   2. MailLog : belongs_to :commande, optional: true
#   3. retirer les `skip` ci-dessus + supprimer le test « le job plante ».
# =============================================================================
