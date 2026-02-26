class WelcomeImportNotificationJob < ApplicationJob
  queue_as :default

  def perform(user, current_user_id, password)
    title = "[CoopComm] Bienvenue !"
    mailer_response = NotificationMailer.welcome_import(user, title, password).deliver_now
    MailLog.create(user_id: current_user_id, message_id: mailer_response.message_id, to: user.email, subject: "Nouvel accès import")
  end
end
