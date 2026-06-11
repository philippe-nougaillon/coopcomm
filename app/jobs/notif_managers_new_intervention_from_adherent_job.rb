# frozen_string_literal: true

class NotifManagersNewInterventionFromAdherentJob < ApplicationJob
  queue_as :default

  def perform(intervention, adherent)
    return unless adherent.services.any?

    manager_ids = []
    adherent.services.each do |service|
      manager_ids += service.managers_and_admin.pluck(:id)
    end

    managers = User.where(id: manager_ids)

    title = "Nouvel intervention d'un adhérent"

    # Mail unique pour des informations plus précises dans le MailLog
    managers.each do |manager|
      mailer_response = NotificationMailer.new_intervention_from_adherent(intervention, manager.email,
                                                                          title).deliver_now
      MailLog.create(organisation_id: manager.organisation_id, user_id: adherent.id || 0,
                     message_id: mailer_response.message_id, to: manager.email, subject: 'Nouvelle intervention adhérent', channel: 0)
    end
  end
end
