# frozen_string_literal: true

class NotifManagersNewAbsenceJob < ApplicationJob
  queue_as :default

  def perform(absence)
    absence_created_by_id = absence.audits.find_by(action: 'create')&.user&.id

    manager_ids = []
    absence.user.services.each do |service|
      manager_ids += service.managers_and_admin.pluck(:id)
    end

    managers = User.where(id: manager_ids).where.not(id: absence_created_by_id)

    # Mail unique pour des informations plus précises dans le MailLog
    managers.each do |manager|
      mailer_response = NotificationMailer.new_absence(absence, manager.email).deliver_now
      MailLog.create(organisation_id: manager.organisation&.id, user_id: absence_created_by_id || 0,
                     message_id: mailer_response.message_id, to: manager.email, subject: 'Nouvelle absence', channel: 0)
    end
  end
end
