class NotifAdherentInterventionPointageJob < ApplicationJob
  queue_as :default

  def perform(intervention)
    adhérent = User.find(intervention.adherent_id)
    mailer_response = NotificationMailer.intervention_pointage(intervention).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: 0, message_id: mailer_response.message_id, to: adhérent.email, subject: "Intervention pointage")

    Notification.create!(message:"Un agent a pointé : \"#{intervention.description}\"", user_id: adhérent.id)
  end
end
