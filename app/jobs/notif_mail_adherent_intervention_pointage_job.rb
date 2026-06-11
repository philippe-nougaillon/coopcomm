# frozen_string_literal: true

class NotifMailAdherentInterventionPointageJob < ApplicationJob
  queue_as :default

  def perform(intervention)
    adhérent = User.find(intervention.adherent_id)

    mailer_response = NotificationMailer.intervention_pointage(intervention).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: 0, message_id: mailer_response.message_id,
                   to: adhérent.email, subject: 'Intervention pointage', channel: 0)

    # Notification.create!(message:"Un agent a pointé : \"#{intervention.description}\"", to_id: adhérent.id)
  end
end
