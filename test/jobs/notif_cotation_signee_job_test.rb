# frozen_string_literal: true

require 'test_helper'

class NotifCotationSigneeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @cotation    = cotations(:cotation_secretariat)
    @creator     = users(:administrateur_paris)
    @signataire  = @cotation.adherent # l'adhérent qui déclenche l'envoi en signant
  end

  test 'le créateur de la cotation reçoit un mail et un mail log attribué au signataire est créé lorsque la cotation est signée' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifCotationSigneeJob.perform_now(@cotation, @creator.id, @signataire.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @creator.email, log.to
    # Le sujet tracé doit être identique à celui réellement envoyé (source unique).
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @cotation.organisation.id, log.organisation_id
    # user_id = celui qui a déclenché l'envoi (le signataire), pas le destinataire.
    assert_equal @signataire.id, log.user_id
    assert_not_equal @creator.id, log.user_id
    assert_equal 'mail', log.channel
    # Le log doit être rattaché à la cotation, pour le retrouver dans l'index.
    assert_equal @cotation.id, log.cotation_id
  end

  test "le mail est adressé au créateur" do
    NotifCotationSigneeJob.perform_now(@cotation, @creator.id, @signataire.id)

    assert_equal [@creator.email], ActionMailer::Base.deliveries.last.to
  end

  test "aucun mail n'est envoyé lorsque le créateur est introuvable" do
    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifCotationSigneeJob.perform_now(@cotation, -1, @signataire.id)
      end
    end
  end

  test "aucun mail n'est envoyé lorsque le créateur n'a pas d'email" do
    @creator.update_columns(email: '')

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifCotationSigneeJob.perform_now(@cotation, @creator.id, @signataire.id)
      end
    end
  end
end
