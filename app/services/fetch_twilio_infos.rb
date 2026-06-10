# frozen_string_literal: true

class FetchTwilioInfos < ApplicationService
  def initialize; end

  def call
    tw_client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    whatsapp_logs = MailLog.where(created_at: [DateTime.now - 20.minutes..DateTime.now], channel: 1)

    whatsapp_logs.each do |whatsapp_log|
      message = tw_client.messages(whatsapp_log.message_id).fetch
      # puts "Message : #{message.error_code}"

      if whatsapp_log.statut && message.status == 'failed'
        whatsapp_log.update!(statut: false, error_message: message.error_code)
        # puts "Mail_log #{whatsapp_log.id} a une erreur : #{whatsapp_log.error_message}"
      end

      if !whatsapp_log.etat && message.status == 'read'
        whatsapp_log.update!(etat: true)
        # puts "Mail_log #{whatsapp_log.id} a été lu"
      end
      # puts '-*' * 50
    end
  end
end
