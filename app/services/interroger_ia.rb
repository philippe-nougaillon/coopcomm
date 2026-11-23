# frozen_string_literal: true

# Pose une question au modèle de langage du GPU (serveur compatible OpenAI, réglé par LLM_HOST, LLM_PORT, LLM_MODEL, LLM_TIMEOUT).
class InterrogerIa < ApplicationService
  class Erreur < StandardError; end
  class Indisponible < Erreur; end

  DELAI_DE_CONNEXION = 5
  SORTIE_MAX = 2_000

  def self.configuree?
    ENV['LLM_HOST'].present?
  end

  def self.adresse
    "http://#{ENV.fetch('LLM_HOST')}:#{ENV.fetch('LLM_PORT', '8000')}"
  end

  def self.disponible?
    Faraday.new(adresse, request: { open_timeout: DELAI_DE_CONNEXION, timeout: DELAI_DE_CONNEXION }).get('/health').success?
  rescue Faraday::Error
    false
  end

  def initialize(consigne:, contenu:, schema: nil, images: [])
    @consigne = consigne
    @contenu = contenu
    @schema = schema
    @images = images
  end

  def call
    verifier_disponibilite
    reponse = chat.ask(@contenu, with: pages_jointes)
    return reponse.content.to_s if @schema.nil?
    raise Erreur, 'réponse coupée avant la fin' if reponse.max_tokens?

    reponse.parsed || raise(Erreur, 'réponse vide')
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError, RubyLLM::ServiceUnavailableError => e
    raise Indisponible, e.message
  rescue RubyLLM::Error => e
    raise Erreur, e.message
  rescue JSON::ParserError
    raise Erreur, 'réponse illisible'
  end

  private

  def adresse
    self.class.adresse
  end

  def verifier_disponibilite
    reponse = Faraday.new(adresse, request: { open_timeout: DELAI_DE_CONNEXION, timeout: DELAI_DE_CONNEXION }).get('/health')
    raise Indisponible, "le serveur du modèle répond #{reponse.status}" unless reponse.success?
  end

  def pages_jointes
    @images.each_with_index.map { |image, rang| RubyLLM::Attachment.new(StringIO.new(image), filename: "page-#{rang + 1}.jpg") }
  end

  # Sans ces réglages, RubyLLM parle l'API Responses d'OpenAI, envoie la consigne en rôle « developer » et rejoue un appel sans réponse.
  def chat
    contexte = RubyLLM.context do |config|
      config.openai_api_base = "#{adresse}/v1"
      config.openai_api_key = 'aucune'
      config.openai_protocol = :chat_completions
      config.openai_use_system_role = true
      config.request_timeout = ENV.fetch('LLM_TIMEOUT', '300').to_i
      config.max_retries = 0
    end
    contexte.chat(model: ENV.fetch('LLM_MODEL', 'mistral-small'), provider: :openai, assume_model_exists: true)
            .with_temperature(0).with_max_output_tokens(SORTIE_MAX).with_instructions(@consigne).with_schema(@schema)
  end
end
