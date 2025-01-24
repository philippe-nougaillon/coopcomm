class NotifAdherentInterventionTermineeJob < ApplicationJob
  queue_as :default

  def perform(intervention, adherent, user_id)
    mailer_response = NotificationMailer.workflow_changed(intervention, adherent.email).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: user_id, message_id: mailer_response.message_id, to: adherent.email, subject: "Intervention terminée", channel: 0)

    Notification.create!(message:"L'équipe \"#{intervention.user.nom_prénom}\" a terminé l'intervention \"#{intervention.description}\"", user_id: adherent.id)
  end
end
