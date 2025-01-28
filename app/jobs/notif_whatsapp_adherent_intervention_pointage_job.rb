class NotifWhatsappAdherentInterventionPointageJob < ApplicationJob
  queue_as :default
  require 'twilio-ruby'

  def perform(intervention)
    adhérent = User.find(intervention.adherent_id)
    client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    response = client.messages.create(body: "Un agent a pointé : \"#{intervention.description}\"", from: "whatsapp:#{ENV['TWILIO_PHONE_NUMBER']}", to: "whatsapp:#{adhérent.téléphone}")
    MailLog.create(organisation_id: intervention.organisation_id, user_id: 0, message_id: response.sid, to: adhérent.téléphone, subject: "Intervention pointage", channel: 1)
  end
end
