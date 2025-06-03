class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token # nécessaire pour les webhooks externes
  skip_before_action :authenticate_user!, only: %i[ whatsapp_reply get_request ]

  def whatsapp_reply
    sender = params['From']
    message = params['Body']

    puts "Réponse de #{sender}: #{message}"

    # Chercher la dernière intervention de l'agent avec le numéro

    agent = User.find_by_whatsapp_phone(sender)

    if (last_intervention_today = agent.intervention_en_cours)
      puts last_intervention_today.inspect
      if last_intervention_today.can_terminer?
        last_intervention_today.terminer!
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention #{last_intervention_today.description} a été terminé avec succès.").to_s
      else
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention #{last_intervention_today.description} n'a pas pu être terminé.").to_s
      end
    else
      render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Aucune intervention n'a été trouvé.").to_s
    end
    puts "Réponse twilio envoyé"

    # if message == "intervention"
    #   send_options
    #   puts "Message envoyé"
    # else
    #   render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Merci pour votre réponse ! Vous avez choisi : #{message}").to_s
    #   puts "Réponse twilio envoyé"
    # end
  end

  def get_request
    puts params
  end

  private

  def send_options
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]
    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
      from: "whatsapp:#{ENV["TWILIO_PHONE_NUMBER"]}",
      to: "whatsapp:#{ENV["TWILIO_PERSONAL_NUMBER"]}",
      content_sid: ENV["CONTENT_SID"]
    )
  end
end