# frozen_string_literal: true

require 'test_helper'

class NotifAdherentFactureEnvoyeeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @facture = factures(:facture_paris)
    @adherent = @facture.adherent
    @sender = users(:administrateur_paris)
  end

  test "l'adhérent reçoit un mail et un mail log est créé lorsque sa facture est envoyée" do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentFactureEnvoyeeJob.perform_now(@facture, @adherent, @sender.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @facture.organisation.id, log.organisation_id
    assert_equal @sender.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test "l'émetteur est mis en copie du mail" do
    NotifAdherentFactureEnvoyeeJob.perform_now(@facture, @adherent, @sender.id)

    assert_equal [@sender.email], ActionMailer::Base.deliveries.last.cc
  end

  test 'le PDF de la facture est joint au mail' do
    NotifAdherentFactureEnvoyeeJob.perform_now(@facture, @adherent, @sender.id)

    piece_jointe = ActionMailer::Base.deliveries.last.attachments.first
    assert_equal @facture.pdf_filename, piece_jointe.filename
    assert piece_jointe.body.raw_source.start_with?('%PDF')
  end

  test 'un émetteur introuvable n\'empêche pas l\'envoi' do
    assert_emails 1 do
      NotifAdherentFactureEnvoyeeJob.perform_now(@facture, @adherent, 0)
    end

    assert_nil ActionMailer::Base.deliveries.last.cc
  end
end
