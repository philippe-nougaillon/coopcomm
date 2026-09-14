# frozen_string_literal: true

class NotifAgentAbsenceJob < ApplicationJob
  queue_as :default

  def perform(action, resume, resume_avant, email, organisation_id, auteur_id)
    mailer_response = NotificationMailer.absence_notification(action, resume, resume_avant, email).deliver_now

    MailLog.create(organisation_id: organisation_id, user_id: auteur_id || 0,
                   message_id: mailer_response.message_id, to: email,
                   subject: "Absence #{action}", channel: 0)
  end
end
