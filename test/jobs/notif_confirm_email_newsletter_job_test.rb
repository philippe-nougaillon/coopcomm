# frozen_string_literal: true

require 'test_helper'

class NotifConfirmEmailNewsletterJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test 'envoie le mail de confirmation à l\'adresse fournie' do
    email = 'futur.abonne@example.com'

    assert_emails 1 do
      NotifConfirmEmailNewsletterJob.perform_now(email)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [email], mail.to
    assert_match(/Confirmation de l'inscription/, mail.subject)
  end

  test 'ne crée aucun MailLog (notification sans traçage)' do
    assert_no_difference -> { MailLog.count } do
      NotifConfirmEmailNewsletterJob.perform_now('autre.abonne@example.com')
    end
  end
end
