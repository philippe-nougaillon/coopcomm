# frozen_string_literal: true

require 'test_helper'
require_relative '../support/compte_aibbo'

class RepondreAibboJobTest < ActiveJob::TestCase
  include CompteAibbo

  VARIABLES_ENV = %w[MISTRAL_AI_API_KEY AIBBO_MODELE DEBUG_AIBOT].freeze
  # La seule adresse que WebMock laisse répondre : toute autre requête fait tomber le test.
  ADRESSE_DU_MODELE = 'https://api.eu.mistral.ai/v1/chat/completions'

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    ENV['MISTRAL_AI_API_KEY'] = 'cle-de-test'
    ENV.delete('AIBBO_MODELE')
    ENV.delete('DEBUG_AIBOT')
    @agent = users(:bond)
    @question = Message.create!(from_user: @agent, to_user: users(:AIBBO), message: 'Combien d’interventions terminées ?')
  end

  teardown do
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  # ==================== TESTS CRITIQUES ====================
  # AÏBBO dépend d'un service tiers : sa panne ne laisse à l'utilisateur qu'un message d'excuse.
  test 'une panne du modèle laisse à l’utilisateur un message d’excuse d’AÏBBO (critique)' do
    stub_request(:post, ADRESSE_DU_MODELE).to_return(status: 503, headers: { 'Content-Type' => 'application/json' }, body: '{}')

    RepondreAibboJob.perform_now(@agent, @question)

    assert_match(/Un problème est survenu avec AÏBBO/, dernier_message_d_aibbo.message)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la réponse du modèle devient un message d’AÏBBO adressé à l’utilisateur' do
    modele_repondant

    RepondreAibboJob.perform_now(@agent, @question)

    assert_equal 'Vous avez des interventions terminées.', dernier_message_d_aibbo.message
  end

  test 'la trace de la réponse est gardée dans un aibot log lorsque le journal est activé' do
    ENV['DEBUG_AIBOT'] = 'true'
    modele_repondant

    RepondreAibboJob.perform_now(@agent, @question)

    aibot_log = AibotLog.find_by(request_message: @question)
    assert aibot_log.succes
    assert_equal dernier_message_d_aibbo, aibot_log.response_message
    assert_match(/api\.eu\.mistral\.ai/, aibot_log.log_stream)
  end

  test 'une panne du modèle est gardée dans un aibot log en échec lorsque le journal est activé' do
    ENV['DEBUG_AIBOT'] = 'true'
    stub_request(:post, ADRESSE_DU_MODELE).to_return(status: 503, headers: { 'Content-Type' => 'application/json' }, body: '{}')

    RepondreAibboJob.perform_now(@agent, @question)

    assert_not AibotLog.find_by(request_message: @question).succes
  end

  test 'aucun aibot log n’est écrit lorsque le journal est désactivé' do
    modele_repondant

    RepondreAibboJob.perform_now(@agent, @question)

    assert_nil AibotLog.find_by(request_message: @question)
  end

  test 'la question est posée au modèle du niveau choisi par l’utilisateur' do
    modele_repondant

    RepondreAibboJob.perform_now(@agent, @question, 'approfondi')

    assert_requested(:post, ADRESSE_DU_MODELE) { |requete| JSON.parse(requete.body)['model'] == 'mistral-large-4' }
  end

  private

  def modele_repondant
    stub_request(:post, ADRESSE_DU_MODELE)
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: file_fixture('responseMistralReponse.json').read)
  end

  def dernier_message_d_aibbo
    Message.message.where(from_user: users(:AIBBO), to_user: @agent).order(:created_at, :id).last
  end
end
