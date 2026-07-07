# frozen_string_literal: true

require 'test_helper'

class MessagerieControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = users(:hidalgo)

    @interlocutor_user = users(:bond)

    sign_in @current_user
  end

  test 'should show messagerie' do
    get messagerie_url
    assert_response :success
  end

  test 'should show a conversation with an interlocutor' do
    get messagerie_conversation_url(@interlocutor_user.id)
    assert_response :success
  end

  test 'conversation with yourself redirects to messagerie' do
    get messagerie_conversation_url(@current_user.id)
    assert_redirected_to messagerie_path
  end

  test 'conversation with an unknown user redirects to messagerie' do
    get messagerie_conversation_url(to_id: 0)
    assert_redirected_to messagerie_path
  end

  test 'should send message' do
    assert_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour',
        to_id: @interlocutor_user.id
      }
    end

    assert_response :success
  end

  test "should'nt send message with yourself" do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour moi-même',
        to_id: @current_user.id
      }
    end

    assert_response :success
  end
end
