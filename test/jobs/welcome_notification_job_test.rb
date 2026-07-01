# frozen_string_literal: true

require 'test_helper'

class WelcomeNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users(:weil)
  end

  test 'envoie le mail de bienvenue à l\'utilisateur' do
    assert_emails 1 do
      WelcomeNotificationJob.perform_now(@user)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], mail.to
    assert_equal '[COOPCOMM] Bienvenue !', mail.subject
  end

  test 'ne crée aucun MailLog (notification sans traçage)' do
    assert_no_difference -> { MailLog.count } do
      WelcomeNotificationJob.perform_now(@user)
    end
  end
end
