# frozen_string_literal: true

require 'test_helper'

class TwilioControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:agent_whatsapp)
    @ancien_token = ENV['TWILIO_AUTH_TOKEN']
    ENV['TWILIO_AUTH_TOKEN'] = 'token-de-test'
  end

  teardown do
    ENV['TWILIO_AUTH_TOKEN'] = @ancien_token
  end

  test "une intervention est créée lorsque l'expéditeur est un agent connu" do
    assert_difference('Intervention.count', 1) do
      post_signé('From' => @agent.téléphone, 'Body' => "Réparation fuite d'eau")
    end

    assert_response :success
    assert_match 'application/xml', response.content_type # On utilise un assert_match car content_type contient aussi le charset
  end

  test "un agent sans service ne crée pas d'intervention" do
    @agent.services.clear

    assert_no_difference 'Intervention.count' do
      post_signé('From' => @agent.téléphone, 'Body' => 'Fuite rue des Lilas')
    end

    assert_response :success
    assert_match 'rattaché à aucun service', response.body
  end

  test "l'intervention d'un agent à plusieurs services prend le premier service dans l'ordre" do
    @agent.services << services(:informatique)

    post_signé('From' => @agent.téléphone, 'Body' => 'Fuite rue des Lilas')

    assert_equal services(:informatique), Intervention.last.service
    assert_equal services(:informatique), @agent.services.ordered.first
  end

  test "aucune intervention n'est créée lorsque l'expéditeur est inconnu" do
    assert_no_difference 'Intervention.count' do
      post_signé('From' => 'whatsapp:+33000000000', 'Body' => 'Hello')
    end

    assert_response :success
    assert_match 'application/xml', response.content_type
  end

  test "un webhook sans paramètre est traité sans planter ni créer d'intervention" do
    assert_no_difference 'Intervention.count' do
      post_signé({})
    end

    assert_response :success
    assert_match 'application/xml', response.content_type
  end

  test 'un webhook sans signature est rejeté' do
    assert_no_difference 'Intervention.count' do
      post twilio_whatsapp_reply_url, params: { 'From' => @agent.téléphone, 'Body' => 'forgé' }
    end

    assert_response :forbidden
  end

  test 'un webhook avec une signature invalide est rejeté' do
    assert_no_difference 'Intervention.count' do
      post twilio_whatsapp_reply_url,
           params: { 'From' => @agent.téléphone, 'Body' => 'forgé' },
           headers: { 'X-Twilio-Signature' => 'AAAA0000' }
    end

    assert_response :forbidden
  end

  private

  # Reproduit la signature HMAC-SHA1 que Twilio joint à chaque webhook
  # (cf. TwilioController#validate_twilio_signature).
  def signature_twilio(url, params)
    data = url + params.sort.map { |k, v| "#{k}#{v}" }.join
    Base64.strict_encode64(OpenSSL::HMAC.digest('sha1', ENV['TWILIO_AUTH_TOKEN'], data))
  end

  def post_signé(params)
    url = twilio_whatsapp_reply_url
    post url, params: params, headers: { 'X-Twilio-Signature' => signature_twilio(url, params) }
  end
end
