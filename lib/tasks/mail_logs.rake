namespace :mail_logs do
  
  desc "Récupérer statut mail_logs"
  task :fetch, [:enregistrer] => :environment do |task, args|
    require 'dotenv/tasks'

    domain = ENV["MAILGUN_DOMAIN"]
    mg_client = Mailgun::Client.new(ENV["MAILGUN_API_KEY"], 'api.eu.mailgun.net')
    events_failed = mg_client.get("#{domain}/events", {event: 'failed'}).to_h
    events_opened = mg_client.get("#{domain}/events", {event: 'opened'}).to_h
    
    mail_logs = MailLog.where(created_at: [DateTime.now-5.days..DateTime.now], channel: 0)
    mail_logs.each do |mail_log|
      # puts "CHECK MAILOG n°#{mail_log.id}"

      # Check erreur
      if mail_log.statut && error_message = events_failed["items"].find{|item| item["message"]["headers"]["message-id"] == mail_log.message_id }
        mail_log.update!(statut: false, error_message: error_message)
        # puts "Mail_log #{mail_log.id} a une erreur : #{mail_log.error_message}"
      end

      # Check lu
      if !mail_log.etat && events_opened["items"].find{|item| item["message"]["headers"]["message-id"] == mail_log.message_id }
        mail_log.update!(etat: true)
        # puts "Mail_log #{mail_log.id} a été lu"
      end
    end

  end

  desc "Récupérer statut mail_logs dans twilio"
  task :fetch_twilio, [:enregistrer] => :environment do |task, args|
    require 'dotenv/tasks'

    tw_client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    whatsapp_logs = MailLog.where(created_at: [DateTime.now-20.minutes..DateTime.now], channel: 1)

    whatsapp_logs.each do |whatsapp_log|
      message = tw_client.messages(whatsapp_log.message_id).fetch
      # puts "Message : #{message.error_code}"

      if whatsapp_log.statut && message.status == "failed"
        whatsapp_log.update!(statut: false, error_message: message.error_code)
        # puts "Mail_log #{whatsapp_log.id} a une erreur : #{whatsapp_log.error_message}"
      end

      if !whatsapp_log.etat && message.status == "read"
        whatsapp_log.update!(etat: true)
        # puts "Mail_log #{whatsapp_log.id} a été lu"
      end
      # puts '-*' * 50
    end

  end

end