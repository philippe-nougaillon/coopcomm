# frozen_string_literal: true

# La seule porte de l'application vers Mistral : une conversation RubyLLM sur le point d'accès européen.
class ChatMistral < ApplicationService
  ADRESSE = 'https://api.eu.mistral.ai/v1'
  MODELE = 'mistral-medium-2604'

  def initialize(modele = MODELE)
    @modele = modele
  end

  def call
    contexte = RubyLLM.context do |config|
      config.mistral_api_key = ENV.fetch('MISTRAL_AI_API_KEY')
      config.mistral_api_base = ADRESSE
      config.request_timeout = 300
      config.max_retries = 2
    end
    # Mistral refuse la température 0 sans top_p à 1 (« top_p must be 1 when using greedy sampling »).
    contexte.chat(model: @modele, provider: :mistral).with_temperature(0).with_provider_options(top_p: 1)
  end
end
