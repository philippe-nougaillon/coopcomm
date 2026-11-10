# frozen_string_literal: true

require 'test_helper'

class WelcomeInscriptionNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @inscrit = users(:administrateur_paris)
  end

  test 'l’inscrit reçoit un mail et un mail log est créé à son inscription' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        WelcomeInscriptionNotificationJob.perform_now(@inscrit)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    log = MailLog.order(:created_at).last
    assert_equal [@inscrit.email], mail.to
    assert_equal @inscrit.email, log.to
    assert_equal mail.subject, log.subject
    assert_equal mail.message_id, log.message_id
    assert_equal @inscrit.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test 'le mail log du mail de bienvenue est rattaché à l’organisation de l’inscrit (critique)' do
    WelcomeInscriptionNotificationJob.perform_now(@inscrit)

    assert_equal organisations(:mairie_paris), MailLog.order(:created_at).last.organisation
  end
end
