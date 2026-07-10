# frozen_string_literal: true

class NotifAgentsAvisChangedJob < ApplicationJob
  queue_as :default

  def perform(intervention, agent_ids, user_id)
    agents = User.where(id: agent_ids)
    mailer_response = NotificationMailer.avis_changed(intervention, agents.pluck(:email)).deliver_now
    MailLog.create(organisation_id: intervention.organisation.id, user_id: user_id,
                   message_id: mailer_response.message_id, to: agents.pluck(:email), subject: 'Nouvel avis', channel: 0)

    agents.each do |agent|
      Notification.create!(message:"L'adhérent \"#{intervention.adherent.nom_prénom}\" a ajouté un avis à l'intervention \"#{intervention.description}\" : \"#{intervention.avis}\"", to_id: agent.id)
    end
  end
end
