class NotifAgentsCommentairesChangedJob < ApplicationJob
  queue_as :default

  def perform(intervention, agent_ids, user_id)
    agents = User.where(id: agent_ids)
    mailer_response = NotificationMailer.commentaires_changed(intervention, agents.pluck(:email)).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: user_id, message_id: mailer_response.message_id, to: agents.pluck(:email), subject: "Nouveau commentaire", channel: 0)

    # agents.each do |agent|
    #   Notification.create!(message:"L'adhérent \"#{intervention.adherent.nom_prénom}\" a ajouté un commentaire à l'intervention \"#{intervention.description}\" : \"#{intervention.commentaires}\"", to_id: agent.id)
    # end
  end
end
