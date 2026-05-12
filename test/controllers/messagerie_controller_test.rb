require "test_helper"

class MessagerieControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:hidalgo)
    
    @interlocutor_user = users(:bond)

    sign_in @user
  end

  test "should show messagerie" do
    get messagerie_url
    assert_response :success
  end

  test "should show messagerie with a to_id" do
    get messagerie_url(to_id: users.second.id)
    assert_response :success
  end

  test "should send message" do
    assert_difference("Message.count") do
      post messagerie_send_message_url, params: {
        message: "Bonjour",
        to_id: @interlocutor_user.id,
      }
    end

    assert_response :success
  end

  test "should'nt send message with yourself" do
    assert_no_difference("Message.count") do
      post messagerie_send_message_url, params: {
        message: "Bonjour moi-même",
        to_id: @user.id,
      }
    end

    assert_response :success
  end
end
