require "test_helper"
require 'minitest/mock'

class FetchMailgunInfosServiceTest < ActionDispatch::IntegrationTest
  def setup
    @domain = "test.example.com"
    @api_key = "test-key-123"
    ENV["MAILGUN_DOMAIN"] = @domain
    ENV["MAILGUN_API_KEY"] = @api_key

    @mail_log = MailLog.create!(
      message_id: "test-message-id",
      statut: true,
      etat: false,
      organisation: organisations(:mairie_paris),
      channel: 0,
      created_at: DateTime.now
    )

    # Préparation des réponses simulées de Mailgun
    @failed_response = {
      "items" => [
        {
          "message" => {
            "headers" => {
              "message-id" => "test-1234"
            }
          },
          "severity" => "permanent",
          "reason" => "suppressed-address",
          "error" => "Email not delivered"
        }
      ]
    }

    @opened_response = {
      "items" => [
        {
          "message" => {
            "headers" => {
              "message-id" => "test-1234"
            }
          },
          "timestamp" => Time.now.to_i
        }
      ]
    }

  end

  test "envoie d'un mailgun avec les bonnes réponses retournées" do
    mock_client = Minitest::Mock.new

    # On s'attend à ce que get soit appelé deux fois avec les bons paramètres
    mock_client.expect(:get, @failed_response, ["#{@domain}/events", {event: 'failed'}])
    mock_client.expect(:get, @opened_response, ["#{@domain}/events", {event: 'opened'}])

    # Stub de la création du client
    Mailgun::Client.stub :new, mock_client do
      FetchMailgunInfos.call
    end

    assert_mock mock_client
  end

  # Tester la présence d'un mail logs
end
