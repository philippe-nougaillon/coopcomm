require "test_helper"
require 'minitest/mock'

class FetchMailgunInfosServiceTest < ActionDispatch::IntegrationTest
  # Infos :
  # Mock de la fonction mailgun pour tester l'appel de ses fonctions et analyser son comportement. 
  # Permet aussi de ne pas utiliser les variables d'environnements réelles.
  
  def setup
    # Préparation de fausses variables d'environnements
    @domain = "test.example.com"
    @api_key = "test-key-123"
    ENV["MAILGUN_DOMAIN"] = @domain
    ENV["MAILGUN_API_KEY"] = @api_key
    
    @mail_log = create_mail_log()
    
    # Préparation des réponses simulées de Mailgun
    @failed_response = get_failed_response()
    @opened_response = get_opened_response()
    
    @mock_client = get_mock_client()
  end



  test "envoie d'un mailgun avec les bonnes réponses retournées" do
    # Stub de la création du client
    Mailgun::Client.stub :new, @mock_client do
      FetchMailgunInfos.call
    end

    assert_mock @mock_client
  end

  test "envoie d'un mailgun avec un message contenant une erreur" do
    @failed_response["items"][0]["message"]["headers"]["message-id"] = @mail_log.message_id

    Mailgun::Client.stub :new, @mock_client do
      FetchMailgunInfos.call
    end

    mail_log_with_error = MailLog.last

    assert (mail_log_with_error.statut == false && mail_log_with_error.error_message = @failed_response["items"])

  end

  test "envoie d'un mailgun avec un message lu" do
    @opened_response["items"][0]["message"]["headers"]["message-id"] = @mail_log.message_id

    Mailgun::Client.stub :new, @mock_client do
      FetchMailgunInfos.call
    end

    mail_log_read = MailLog.last

    assert (mail_log_read.etat = true)

  end

  def get_mock_client
    mock_client = Minitest::Mock.new
    # On s'attend à ce que get soit appelé deux fois avec les bons paramètres
    mock_client.expect(:get, @failed_response, ["#{@domain}/events", {event: 'failed'}])
    mock_client.expect(:get, @opened_response, ["#{@domain}/events", {event: 'opened'}])
  end

  def create_mail_log
    MailLog.create!(
      message_id: "test-message-id",
      statut: true,
      etat: false,
      organisation: organisations(:mairie_paris),
      channel: 0,
      created_at: DateTime.now
    )
  end

  def get_failed_response
    {
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
  end

  def get_opened_response
    {
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

end
