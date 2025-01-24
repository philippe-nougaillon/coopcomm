class NotifManagersWorkflowChangedJob < ApplicationJob
  queue_as :default

  def perform(intervention, manager_ids, user_id)
    managers = User.where(id: manager_ids)
    mailer_response = NotificationMailer.workflow_changed(intervention, managers.pluck(:email)).deliver_now
    MailLog.create(organisation_id: intervention.organisation_id, user_id: user_id, message_id: mailer_response.message_id, to: managers.pluck(:email), subject: "Changement de statut", channel: 0)

    managers.each do |manager|
      Notification.create!(message:"L'intervention \"#{intervention.description}\" a changé de statut (#{intervention.workflow_state.humanize})", user_id: manager.id)
    end
  end
end
