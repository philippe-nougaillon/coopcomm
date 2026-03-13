class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token # nécessaire pour les webhooks externes
  skip_before_action :authenticate_user!, only: %i[ whatsapp_reply get_request ]

  def whatsapp_reply
    sender = params['From']
    message = params['Body']

    agent = User.agent.find_by_whatsapp_phone(sender) if sender.present?

    if sender.present? && message.present? && agent
      if intervention = Intervention.create!(description: "[WhatsApp] #{l(DateTime.now, format: :long)} #{sender.gsub("whatsapp:", '')}", organisation_id: agent.organisation_id, commentaires: message)
        # Pas de test de chevauchement d'intervention puisqu'il n'y a aucune date dans ce qu'il y a envoyé
        intervention.agent_interventions.create(agent:)
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Intervention créée avec succès.").to_s
      else
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention n'a pas pu être créée : #{intervention.errors.full_messages}").to_s
      end
    else
      render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Votre numéro de téléphone n'est associé à aucun agent. Veuillez contacter un manageur.").to_s
    end
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

  def terminer_intervention
    agent = User.find_by_whatsapp_phone(sender)

    if (agent && last_intervention_today = agent.intervention_en_cours)
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
  end
end