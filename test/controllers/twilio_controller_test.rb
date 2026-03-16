require "test_helper"

class TwilioControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:agent_whatsapp)
  end

  test "should create intervention when sender exists" do
    assert_difference("Intervention.count", 1) do 
      post twilio_whatsapp_reply_url, params: { 
        'From' => @agent.téléphone, 
        'Body' => "Réparation fuite d'eau" 
      }
    end

    assert_response :success
    assert_match "application/xml", response.content_type # On utilise un assert_match car content_type contient aussi le charset
  end

  test "should return error message when sender is unknown" do
    assert_no_difference "Intervention.count" do
      post twilio_whatsapp_reply_url, params: { 
        'From' => "whatsapp:+33000000000", 
        'Body' => "Hello" 
      }
    end

    assert_response :success
    assert_match "application/xml", response.content_type
  end

  test "should handle missing params gracefully" do
    assert_no_difference "Intervention.count" do
      post twilio_whatsapp_reply_url, params: {} 
    end

    assert_response :success
    assert_match "application/xml", response.content_type
  end
end