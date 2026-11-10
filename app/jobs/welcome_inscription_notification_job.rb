# frozen_string_literal: true

class WelcomeInscriptionNotificationJob < ApplicationJob
  queue_as :default

  def perform(user)
    mailer_response = NotificationMailer.welcome_inscription(user).deliver_now

    MailLog.create!(organisation_id: user.organisation.id, user_id: user.id,
                    message_id: mailer_response.message_id, to: user.email,
                    subject: mailer_response.subject, channel: 0)
  end
end
