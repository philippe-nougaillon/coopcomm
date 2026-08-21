# frozen_string_literal: true

class NotifManagerCotationRefuseeJob < ApplicationJob
  queue_as :default

  def perform(cotation, manager, user_id)
    sender = User.find_by(id: user_id)

    mailer_response = NotificationMailer.cotation_refusee(cotation, manager.email, sender&.email).deliver_now

    MailLog.create(organisation_id: cotation.organisation&.id, user_id: user_id,
                   cotation_id: cotation.id,
                   message_id: mailer_response.message_id, to: manager.email,
                   subject: mailer_response.subject, channel: 0)
  end
end
