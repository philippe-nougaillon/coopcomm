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
      content_sid: 'HX1fd1680c80e842aff7e88e668744034a'
    )

    puts message.body
  end

  def whatsapp_reply
    sender = params['From']
    message = params['Body']

    puts "Réponse de #{sender}: #{message}"

    if user = User.where(rôle: [0,2]).find_by(téléphone: sender.gsub("whatsapp:", ""))
      puts "Réponse twilio envoyé"

      account_sid = ENV["TWILIO_ACCOUNT_SID"]
      auth_token = ENV["TWILIO_AUTH_TOKEN"]
      client = Twilio::REST::Client.new(account_sid, auth_token)

      message = client.messages.create(
        from: "whatsapp:#{ENV["TWILIO_PHONE_NUMBER"]}",
        to: "whatsapp:#{ENV["TWILIO_PERSONAL_NUMBER"]}",
        content_sid: 'HX6d81eb2d30ad61cb0ef90c8fedf20687'
      )

      if intervention.save
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Merci pour ta réponse ! Vous avez choisi : #{message}").to_s
      else
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention n'a pas pu être créée : #{intervention.errors.full_messages}").to_s
      end

    end

  end
end