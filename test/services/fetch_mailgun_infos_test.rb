# frozen_string_literal: true

require 'test_helper'

class FetchMailgunInfosTest < ActiveSupport::TestCase
  DOMAINE = 'test.example.com'
  CLE_API = 'cle-de-test'
  URL_EVENEMENTS = "https://api.eu.mailgun.net/v3/#{DOMAINE}/events"

  setup do
    @domaine_initial = ENV.fetch('MAILGUN_DOMAIN', nil)
    @cle_initiale = ENV.fetch('MAILGUN_API_KEY', nil)
    ENV['MAILGUN_DOMAIN'] = DOMAINE
    ENV['MAILGUN_API_KEY'] = CLE_API

    stub_evenements('failed', reponse_evenements_en_echec)
    stub_evenements('opened', reponse_evenements_ouverts)
  end

  teardown do
    ENV['MAILGUN_DOMAIN'] = @domaine_initial
    ENV['MAILGUN_API_KEY'] = @cle_initiale
  end

  test 'la relève interroge les événements en échec puis les événements ouverts' do
    FetchMailgunInfos.call

    assert_requested :get, URL_EVENEMENTS, query: { event: 'failed' },
                                           headers: { 'Authorization' => authentification_attendue }
    assert_requested :get, URL_EVENEMENTS, query: { event: 'opened' },
                                           headers: { 'Authorization' => authentification_attendue }
  end

  test 'un message en échec passe le mail log en erreur' do
    mail_log = mail_log_mail_gun(message_id: 'echec@test.example.com')

    FetchMailgunInfos.call

    assert_not mail_log.reload.statut
    assert_equal 'suppressed-address', mail_log.error_message['reason']
  end

  test 'un message ouvert passe le mail log à lu' do
    mail_log = mail_log_mail_gun(message_id: 'ouvert@test.example.com')

    FetchMailgunInfos.call

    assert mail_log.reload.etat
  end

  test 'un identifiant de message inconnu laisse le mail log intact' do
    mail_log = mail_log_mail_gun(message_id: 'jamais-vu@test.example.com')

    FetchMailgunInfos.call
    mail_log.reload

    assert mail_log.statut
    assert_not mail_log.etat
  end

  test 'un mail log plus vieux que cinq jours n’est pas relevé' do
    mail_log = mail_log_mail_gun(message_id: 'ouvert@test.example.com', created_at: 6.days.ago)

    FetchMailgunInfos.call

    assert_not mail_log.reload.etat
  end

  test 'un mail log WhatsApp n’est pas relevé par la relève des mails' do
    mail_log = mail_log_mail_gun(message_id: 'ouvert@test.example.com', channel: 1)

    FetchMailgunInfos.call

    assert_not mail_log.reload.etat
  end

  # ÉPINGLAGE — à inverser à la correction : le service n'a aucun rescue, donc
  # une API en erreur remonte jusqu'à `mail_logs#refresh` et met la page en 500.
  test 'une API en erreur fait remonter l’exception au lieu d’être absorbée' do
    stub_request(:get, URL_EVENEMENTS).with(query: { event: 'failed' }).to_return(status: 502)

    assert_raises(Mailgun::CommunicationError) { FetchMailgunInfos.call }
  end

  private

  def stub_evenements(evenement, corps)
    stub_request(:get, URL_EVENEMENTS)
      .with(query: { event: evenement })
      .to_return(status: 200, body: corps, headers: { 'Content-Type' => 'application/json' })
  end

  def reponse_evenements_en_echec
    file_fixture('responseMailgunEventsFailed.json').read
  end

  def reponse_evenements_ouverts
    file_fixture('responseMailgunEventsOpened.json').read
  end

  def authentification_attendue
    "Basic #{Base64.strict_encode64("api:#{CLE_API}")}"
  end

  def mail_log_mail_gun(message_id:, channel: 0, created_at: Time.current)
    MailLog.create!(message_id: message_id, statut: true, etat: false, channel: channel,
                    created_at: created_at, organisation: organisations(:mairie_paris))
  end
end
