# frozen_string_literal: true

class FetchMailgunInfos < ApplicationService
  def initialize; end

  def call
    domain = ENV['MAILGUN_DOMAIN']
    mg_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY'], 'api.eu.mailgun.net')
    events_failed = mg_client.get("#{domain}/events", { event: 'failed' }).to_h
    events_opened = mg_client.get("#{domain}/events", { event: 'opened' }).to_h

    mail_logs = MailLog.where(created_at: [DateTime.now - 5.days..DateTime.now], channel: 0)
    mail_logs.each do |mail_log|
      # puts "CHECK MAILOG n°#{mail_log.id}"

      # Check erreur
      if mail_log.statut && (error_message = events_failed['items'].find do |item|
        item['message']['headers']['message-id'] == mail_log.message_id
      end)
        mail_log.update!(statut: false, error_message: error_message)
        # puts "Mail_log #{mail_log.id} a une erreur : #{mail_log.error_message}"

        # On arrête pour ce mail car il a une erreur
        next
      end

      # Check lu
      next unless !mail_log.etat && events_opened['items'].find do |item|
        item['message']['headers']['message-id'] == mail_log.message_id
      end

      mail_log.update!(etat: true)
      # puts "Mail_log #{mail_log.id} a été lu"
    end
  end
end
