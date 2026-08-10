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
    get messagerie_conversation_url(@interlocutor_user.slug)
    assert_response :success
  end

  test 'conversation with yourself redirects to messagerie' do
    get messagerie_conversation_url(@current_user.slug)
    assert_redirected_to messagerie_path
  end

  test 'conversation with an unknown user redirects to messagerie' do
    get messagerie_conversation_url(to_user_slug: 0)
    assert_redirected_to messagerie_path
  end

  test 'should send message' do
    assert_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour',
        to_user_slug: @interlocutor_user.slug
      }
    end

    assert_response :success
  end

  test "should'nt send message with yourself" do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour moi-même',
        to_user_slug: @current_user.slug
      }
    end

    assert_response :success
  end

  # --- mark_as_read ---

  test 'mark_as_read marque comme lu un message qui m\'est destiné' do
    message = Message.create!(message: 'Bonjour', from_id: @interlocutor_user.id, to_id: @current_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_not_nil message.reload.read_at
  end

  test 'mark_as_read ne touche pas au message d\'un autre destinataire' do
    message = Message.create!(message: 'Pas pour moi', from_id: @current_user.id, to_id: @interlocutor_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_nil message.reload.read_at
  end

  test 'mark_as_read est idempotent sur un message déjà lu' do
    message = Message.create!(message: 'Déjà lu', from_id: @interlocutor_user.id, to_id: @current_user.id,
                              read_at: 2.days.ago)
    lu_le = message.read_at

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_equal lu_le.to_i, message.reload.read_at.to_i
  end

  # --- search_contact ---

  test 'search_contact liste les contacts du périmètre sans moi-même' do
    post messagerie_search_contact_url

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), @current_user
  end

  test 'search_contact filtre sur le nom' do
    post messagerie_search_contact_url, params: { query: 'Bond' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), users(:martin_technique_paris)
  end

  test 'search_contact filtre aussi sur le prénom' do
    post messagerie_search_contact_url, params: { query: 'James' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
  end
end
