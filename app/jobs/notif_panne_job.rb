# frozen_string_literal: true

class NotifPanneJob < ApplicationJob
  queue_as :default

  def perform(mouvement_id, reservation_id)
    panne = Mouvement.find(mouvement_id)
    réservation = Mouvement.find(reservation_id)

    title = "[COOPCOMM] L'outil #{panne.tool.name} a été déclaré en panne"

    mailer_response = NotificationMailer.avertissement_reservation(
      réservation.user,
      panne.tool,
      réservation.date,
      panne.date,
      title: title
    ).deliver_now
    MailLog.create(organisation_id: panne.tool.organisation_id, user_id: panne.user_id || 0,
                   message_id: mailer_response.message_id, to: réservation.user.email, subject: title, channel: 0)
  end
end
