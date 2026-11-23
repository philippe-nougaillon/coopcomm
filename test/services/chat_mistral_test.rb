# frozen_string_literal: true

require 'test_helper'

class ChatMistralTest < ActiveSupport::TestCase
  # La seule adresse que WebMock laisse répondre : toute autre requête fait tomber le test.
  ADRESSE_DU_MODELE = 'https://api.eu.mistral.ai/v1/chat/completions'

  setup do
    @clé_initiale = ENV.fetch('MISTRAL_AI_API_KEY', nil)
    ENV['MISTRAL_AI_API_KEY'] = 'cle-de-test'
    stub_request(:post, ADRESSE_DU_MODELE)
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: file_fixture('responseMistralReponse.json').read)
  end

  teardown do
    ENV['MISTRAL_AI_API_KEY'] = @clé_initiale
  end

  test 'une conversation ne parle qu’au point d’accès européen de Mistral (critique)' do
    ChatMistral.call.ask('Bonjour')

    assert_requested :post, ADRESSE_DU_MODELE, times: 1
  end

  test 'la requête part à température nulle avec top_p à un, que Mistral exige ensemble' do
    ChatMistral.call.ask('Bonjour')

    assert_requested(:post, ADRESSE_DU_MODELE) do |requete|
      corps = JSON.parse(requete.body)
      corps['temperature'].zero? && corps['top_p'] == 1
    end
  end

  test 'le modèle demandé est celui du service par défaut' do
    ChatMistral.call.ask('Bonjour')

    assert_requested(:post, ADRESSE_DU_MODELE) { |requete| JSON.parse(requete.body)['model'] == ChatMistral::MODELE }
  end

  test 'un autre modèle peut être demandé' do
    ChatMistral.call('mistral-large-4').ask('Bonjour')

    assert_requested(:post, ADRESSE_DU_MODELE) { |requete| JSON.parse(requete.body)['model'] == 'mistral-large-4' }
  end
end
