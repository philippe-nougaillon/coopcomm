# frozen_string_literal: true

require 'test_helper'

class FetchTwilioInfosTest < ActiveSupport::TestCase
  COMPTE = 'AC00000000000000000000000000000000'
  JETON = 'jeton-de-test'
  MESSAGE = 'SM00000000000000000000000000000000'
  URL_MESSAGE = "https://api.twilio.com/2010-04-01/Accounts/#{COMPTE}/Messages/#{MESSAGE}.json"

  setup do
    @compte_initial = ENV.fetch('TWILIO_ACCOUNT_SID', nil)
    @jeton_initial = ENV.fetch('TWILIO_AUTH_TOKEN', nil)
    ENV['TWILIO_ACCOUNT_SID'] = COMPTE
    ENV['TWILIO_AUTH_TOKEN'] = JETON
  end

  teardown do
    ENV['TWILIO_ACCOUNT_SID'] = @compte_initial
    ENV['TWILIO_AUTH_TOKEN'] = @jeton_initial
  end

  test 'la relève interroge le message par son identifiant' do
    stub_message(reponse_message_lu)
    mail_log_whatsapp

    FetchTwilioInfos.call

    assert_requested :get, URL_MESSAGE, headers: { 'Authorization' => authentification_attendue }
  end

  test 'un message en échec passe le mail log en erreur' do
    stub_message(reponse_message_en_echec)
    mail_log = mail_log_whatsapp

    FetchTwilioInfos.call
    mail_log.reload

    assert_not mail_log.statut
    assert_equal 63_016, mail_log.error_message
  end

  test 'un message lu passe le mail log à lu' do
    stub_message(reponse_message_lu)
    mail_log = mail_log_whatsapp

    FetchTwilioInfos.call

    assert mail_log.reload.etat
  end

  test 'un message encore en cours de remise laisse le mail log intact' do
    stub_message(reponse_message_lu.sub('"read"', '"sent"'))
    mail_log = mail_log_whatsapp

    FetchTwilioInfos.call
    mail_log.reload

    assert mail_log.statut
    assert_not mail_log.etat
  end

  test 'un mail log plus vieux que vingt minutes n’est pas relevé' do
    stub_message(reponse_message_lu)
    mail_log = mail_log_whatsapp(created_at: 21.minutes.ago)

    FetchTwilioInfos.call

    assert_not mail_log.reload.etat
    assert_not_requested :get, URL_MESSAGE
  end

  test 'un mail log mail n’est pas relevé par la relève WhatsApp' do
    stub_message(reponse_message_lu)
    mail_log = mail_log_whatsapp(channel: 0)

    FetchTwilioInfos.call

    assert_not mail_log.reload.etat
    assert_not_requested :get, URL_MESSAGE
  end

  # ÉPINGLAGE — à inverser à la correction : le service n'a aucun rescue, donc
  # une API en erreur remonte jusqu'à `mail_logs#refresh` et met la page en 500.
  test 'une API en erreur fait remonter l’exception au lieu d’être absorbée' do
    stub_request(:get, URL_MESSAGE).to_return(status: 502, body: '{}',
                                              headers: { 'Content-Type' => 'application/json' })
    mail_log_whatsapp

    assert_raises(Twilio::REST::RestError) { FetchTwilioInfos.call }
  end

  private

  def stub_message(corps)
    stub_request(:get, URL_MESSAGE)
      .to_return(status: 200, body: corps, headers: { 'Content-Type' => 'application/json' })
  end

  def reponse_message_en_echec
    file_fixture('responseTwilioMessageFailed.json').read
  end

  def reponse_message_lu
    file_fixture('responseTwilioMessageRead.json').read
  end

  def authentification_attendue
    "Basic #{Base64.strict_encode64("#{COMPTE}:#{JETON}")}"
  end

  def mail_log_whatsapp(channel: 1, created_at: Time.current)
    MailLog.create!(message_id: MESSAGE, statut: true, etat: false, channel: channel,
                    created_at: created_at, organisation: organisations(:mairie_paris))
  end
end
