# frozen_string_literal: true

require 'test_helper'

class NotifAdherentCotationsASignerRelanceJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @adherent  = users(:weil)
    # weil a une seule cotation en état « envoyé » (cotation_secretariat) ;
    # cotation_paris reste en « créé » (donc pas à signer).
    @a_signer  = cotations(:cotation_secretariat)
  end

  test "l'adhérent reçoit un mail de relance et un mail log est créé lorsqu'il a une cotation à signer" do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentCotationsASignerRelanceJob.perform_now(@adherent)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    # Le sujet tracé doit être identique à celui réellement envoyé (source unique).
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @a_signer.organisation.id, log.organisation_id
    # user_id = 0 : c'est le système (tâche planifiée) qui émet, pas un utilisateur.
    assert_equal 0, log.user_id
    assert_equal 'mail', log.channel
    # Rattaché à une cotation à signer, pour la garde des 48h côté tâche.
    assert_equal @a_signer.id, log.cotation_id
  end

  test 'le mail est adressé à l\'adhérent' do
    NotifAdherentCotationsASignerRelanceJob.perform_now(@adherent)

    assert_equal [@adherent.email], ActionMailer::Base.deliveries.last.to
  end

  test "le mail de relance liste toutes les cotations à signer de l'adhérent" do
    # On bascule une seconde cotation de weil en « envoyé ».
    cotations(:cotation_paris).update_column(:workflow_state, Cotation::ENVOYE)

    NotifAdherentCotationsASignerRelanceJob.perform_now(@adherent)

    body = ActionMailer::Base.deliveries.last.body.encoded
    assert_includes body, cotations(:cotation_secretariat).ref
    assert_includes body, cotations(:cotation_paris).ref
  end

  test "aucun mail n'est envoyé lorsque l'adhérent n'a aucune cotation à signer" do
    sans_cotation = users(:adhérent_sans_intervention)

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifAdherentCotationsASignerRelanceJob.perform_now(sans_cotation)
      end
    end
  end

  test "aucun mail n'est envoyé lorsque la cotation a été signée entre-temps" do
    # La cotation quitte l'état « envoyé » après la sélection de la tâche.
    @a_signer.update_column(:workflow_state, Cotation::SIGNE)

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifAdherentCotationsASignerRelanceJob.perform_now(@adherent)
      end
    end
  end

  test "aucun mail n'est envoyé sans adhérent" do
    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifAdherentCotationsASignerRelanceJob.perform_now(nil)
      end
    end
  end

  test "aucun mail n'est envoyé lorsque l'adhérent n'a pas d'email" do
    @adherent.update_columns(email: '')

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifAdherentCotationsASignerRelanceJob.perform_now(@adherent)
      end
    end
  end
end
