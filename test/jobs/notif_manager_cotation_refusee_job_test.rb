# frozen_string_literal: true

require 'test_helper'

class NotifManagerCotationRefuseeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @cotation = cotations(:cotation_secretariat)
    @manager  = users(:administrateur_paris) # créateur de la cotation (audit de création)
    @adherent = @cotation.adherent           # l'adhérent qui refuse, donc déclenche l'envoi
  end

  test 'envoie un mail au créateur et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifManagerCotationRefuseeJob.perform_now(@cotation, @manager, @adherent.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @manager.email, log.to
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @cotation.organisation.id, log.organisation_id
    # user_id = celui qui a refusé, pas le destinataire.
    assert_equal @adherent.id, log.user_id
    assert_not_equal @manager.id, log.user_id
    assert_equal 'mail', log.channel
    assert_equal @cotation.id, log.cotation_id
  end

  test 'le mail est adressé au créateur, avec en copie celui qui a refusé' do
    NotifManagerCotationRefuseeJob.perform_now(@cotation, @manager, @adherent.id)

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@manager.email], mail.to
    assert_equal [@adherent.email], mail.cc
  end

  test 'le mail nomme la cotation et son adhérent' do
    NotifManagerCotationRefuseeJob.perform_now(@cotation, @manager, @adherent.id)

    corps = ActionMailer::Base.deliveries.last.body.decoded
    assert_includes corps, @cotation.ref
    assert_includes corps, @cotation.intitulé
    assert_includes corps, @adherent.nom_prénom
  end
end
