class NotifAdherentInterventionPointageJob < ApplicationJob
  queue_as :default

  def perform(intervention)
    adhérent = User.find(intervention.adherent_id)
    mailer_response = NotificationMailer.intervention_pointage(intervention).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: intervention.agents.first.id, message_id: mailer_response.message_id, to: adhérent.email, subject: "Intervention pointage")

    Notification.create!(message:"L'agent \"#{intervention.agents.first.nom_prénom}\" a pointé : \"#{intervention.description}\"", user_id: adhérent.id)
  end
end
