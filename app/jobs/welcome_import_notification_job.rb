# frozen_string_literal: true

class WelcomeImportNotificationJob < ApplicationJob
  queue_as :default

  def perform(user, current_user_id, encrypted_password)
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret_key = Rails.application.key_generator.generate_key('import_password', key_len)
    encryptor = ActiveSupport::MessageEncryptor.new(secret_key)
    decrypted_password = encryptor.decrypt_and_verify(encrypted_password)

    title = '[CoopComm] Bienvenue !'

    mailer_response = NotificationMailer.welcome_import(user, title, decrypted_password).deliver_now
    MailLog.create(user_id: current_user_id, message_id: mailer_response.message_id, to: user.email,
                   subject: 'Nouvel accès import')
  end
end
