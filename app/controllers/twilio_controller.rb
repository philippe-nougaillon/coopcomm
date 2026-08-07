# frozen_string_literal: true

class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token # nécessaire pour les webhooks externes
  skip_before_action :authenticate_user!, only: %i[whatsapp_reply]
  # Webhook machine-à-machine : l'autorisation est portée par la signature ci-dessous
  skip_after_action :verify_authorized
  
  # CSRF et authentification étant désactivés, la signature Twilio est le SEUL
  # garde-fou : sans elle, n'importe qui peut forger des webhooks depuis Internet.
  before_action :validate_twilio_signature, only: %i[whatsapp_reply]


  def whatsapp_reply
    sender = params['From']
    message = params['Body']

    agent = User.agent.find_by_whatsapp_phone(sender) if sender.present?

    if sender.blank? || message.blank? || agent.nil?
      return render xml: reponse_whatsapp("Votre numéro de téléphone n'est associé à aucun agent. Veuillez contacter un manageur.")
    end

    # ordered : sans ordre explicite, « le premier service » varie d'un appel à l'autre.
    service = agent.services.ordered.first

    if service.nil?
      return render xml: reponse_whatsapp("Votre compte n'est rattaché à aucun service. Veuillez contacter un manageur.")
    end

    intervention = Intervention.new(
      description: "[WhatsApp] #{l(DateTime.now, format: :long)} #{sender.gsub('whatsapp:', '')}",
      commentaires: message, service: service, workflow_state: 'nouveau'
    )
    # Brouillon à compléter : l'adhérent concerné n'est pas connu depuis le terrain.
    intervention.save!(validate: false)
    intervention.agent_interventions.create(agent:)

    render xml: reponse_whatsapp('Intervention créée avec succès.')
  end

  private

  def reponse_whatsapp(corps)
    Twilio::TwiML::MessagingResponse.new.message(body: corps).to_s
  end

  def validate_twilio_signature
    validator = Twilio::Security::RequestValidator.new(ENV['TWILIO_AUTH_TOKEN'].to_s)
    signature = request.headers['X-Twilio-Signature'].to_s

    head :forbidden unless signature.present? && validator.validate(request.original_url, request.POST, signature)
  end

  def send_options
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']
    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
      from: "whatsapp:#{ENV['TWILIO_PHONE_NUMBER']}",
      to: "whatsapp:#{ENV['TWILIO_PERSONAL_NUMBER']}",
      content_sid: ENV['CONTENT_SID']
    )
  end

  def terminer_intervention
    agent = User.find_by_whatsapp_phone(sender)

    if agent && (last_intervention_today = agent.intervention_en_cours)
      puts last_intervention_today.inspect
      last_intervention_today.fin = Time.current

      if last_intervention_today.can_terminer? && terminer_sans_erreur(last_intervention_today)
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention #{last_intervention_today.description} a été terminé avec succès.").to_s
      else
        render xml: Twilio::TwiML::MessagingResponse.new.message(body: "L'intervention #{last_intervention_today.description} n'a pas pu être terminé.").to_s
      end
    else
      render xml: Twilio::TwiML::MessagingResponse.new.message(body: "Aucune intervention n'a été trouvé.").to_s
    end
    puts 'Réponse twilio envoyé'
  end

  def terminer_sans_erreur(intervention)
    intervention.terminer!
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
