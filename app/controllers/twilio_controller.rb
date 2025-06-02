class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token # nécessaire pour les webhooks externes
  skip_before_action :authenticate_user!, only: %i[ whatsapp_reply ]

  def choisir_nom_intervention
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    auth_token = ENV["TWILIO_AUTH_TOKEN"]
    client = Twilio::REST::Client.new(account_sid, auth_token)

    message = client.messages.create(
      from: "whatsapp:#{ENV["TWILIO_PHONE_NUMBER"]}",
      to: "whatsapp:#{ENV["TWILIO_PERSONAL_NUMBER"]}",
      content_sid: 'HX6d81eb2d30ad61cb0ef90c8fedf20687'
    )

    puts message.body
    redirect_to root_path, notice: "Message envoyé avec succès. #{message.body}"
  end

  def whatsapp_reply
    sender = params['From']
    message = params['Body']

    puts "Réponse de #{sender}: #{message}"

    if user = User.where(rôle: [0,2]).find_by(téléphone: sender.gsub("whatsapp:", ""))

      if message == "intervention"
        send_message
        puts "Message envoyé"
      else
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Merci pour votre réponse ! Vous avez choisi : #{message}").to_s
        puts "Réponse twilio envoyé"
      end
    end
  end

  private

    def send_message
      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new(account_sid, auth_token)

      client.messages.create(
        from: "whatsapp:#{ENV["TWILIO_PHONE_NUMBER"]}",
        to: "whatsapp:#{ENV["TWILIO_PERSONAL_NUMBER"]}",
        content_sid: 'HX6d81eb2d30ad61cb0ef90c8fedf20687'
      )
    end
end