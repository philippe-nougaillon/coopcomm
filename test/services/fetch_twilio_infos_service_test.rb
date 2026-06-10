# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'
require 'ostruct'

class FetchTwilioInfosServiceTest < ActionDispatch::IntegrationTest
  def setup
    # Préparation de fausses variables d'environnements
    ENV['TWILIO_ACCOUNT_SID'] = 'abcd'
    ENV['TWILIO_AUTH_TOKEN'] = '1234'

    @whatsapp_log = create_whatsapp_log

    # Préparation des réponses simulées de twilio
    @read_message = get_read_message
    @failed_message = get_failed_message

    @mock_client = nil
  end

  test "envoie d'un message whatsapp" do
    mock_client = get_mock_client_with(@read_message)

    Twilio::REST::Client.stub :new, mock_client do
      FetchTwilioInfos.call
    end

    assert_mock mock_client
  end

  test "envoie d'un message whatsapp avec une erreur" do
    mock_client = get_mock_client_with(@failed_message)

    Twilio::REST::Client.stub :new, mock_client do
      FetchTwilioInfos.call
    end

    mail_log_with_error = MailLog.last

    assert mail_log_with_error.statut == false && mail_log_with_error.error_message == @failed_message.error_code
  end

  test "envoie d'un message whatsapp lu" do
    mock_client = get_mock_client_with(@read_message)

    Twilio::REST::Client.stub :new, mock_client do
      FetchTwilioInfos.call
    end

    mail_log_with_error = MailLog.last

    assert mail_log_with_error.etat == true
  end

  def get_mock_client_with(message)
    message_proxy = Minitest::Mock.new
    message_proxy.expect(:fetch, message)

    mock_client = Minitest::Mock.new
    mock_client.expect(:messages, message_proxy, [@whatsapp_log.message_id])

    mock_client
  end

  def create_whatsapp_log
    MailLog.create!(
      message_id: 'test-message-id',
      statut: true,
      etat: false,
      organisation: organisations(:mairie_paris),
      channel: 1,
      created_at: DateTime.now
    )
  end

  # Pour créer un object message
  def get_failed_message
    OpenStruct.new(
      status: 'failed',
      error_code: 500,
      body: 'Message de test échoué',
      sid: 'SMXXXXXXXX'
    )
  end

  def get_read_message
    OpenStruct.new(
      status: 'read',
      body: 'Message de test lu',
      sid: 'SMXXXXXXXX'
    )
  end
end
