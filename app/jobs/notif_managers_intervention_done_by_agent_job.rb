# frozen_string_literal: true

class NotifManagersInterventionDoneByAgentJob < ApplicationJob
  queue_as :default

  def perform(intervention, agent)
    return unless agent.services.any?

    manager_ids = []
    agent.services.each do |service|
      manager_ids += service.managers_and_admin.pluck(:id)
    end

    managers = User.where(id: manager_ids)

    title = "Nouveau bon d'intervention d'un agent"

    # Mail unique pour des informations plus précises dans le MailLog
    managers.each do |manager|
      mailer_response = NotificationMailer.intervention_done_by_agent(intervention, manager.email, title).deliver_now
      MailLog.create(organisation_id: manager.organisation_id, user_id: agent.id || 0,
                     message_id: mailer_response.message_id, to: manager.email, subject: "Bon d'intervention agent", channel: 0)
    end
  end
end
