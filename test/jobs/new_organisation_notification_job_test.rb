# frozen_string_literal: true

require 'test_helper'

class NewOrganisationNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @organisation = organisations(:mairie_paris)
    # Le mailer adresse la notification à l'adresse d'admin système (ENV) ;
    # on la fixe pour rendre le mail effectivement délivrable et déterministe.
    @previous_bcc = ENV['BCC_NOTIFICATION_EMAILS']
    ENV['BCC_NOTIFICATION_EMAILS'] = 'admin-systeme@example.com'
  end

  teardown do
    ENV['BCC_NOTIFICATION_EMAILS'] = @previous_bcc
  end

  test 'envoie la notification de nouvelle organisation' do
    assert_emails 1 do
      NewOrganisationNotificationJob.perform_now(@organisation)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ENV['BCC_NOTIFICATION_EMAILS']], mail.to
    assert_match(/Nouvelle Organisation/, mail.subject)
  end
end
