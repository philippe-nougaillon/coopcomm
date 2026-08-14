# frozen_string_literal: true

require 'test_helper'

class MessagerieControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = users(:hidalgo)

    @interlocutor_user = users(:bond)

    sign_in @current_user
  end

  test 'index : sans paramètre → la page répond' do
    get messagerie_url
    assert_response :success
  end

  test 'conversation : un interlocuteur du périmètre → la page répond' do
    get messagerie_conversation_url(@interlocutor_user.slug)
    assert_response :success
  end

  test 'conversation : avec soi-même → retour à la messagerie' do
    get messagerie_conversation_url(@current_user.slug)
    assert_redirected_to messagerie_path
  end

  test 'conversation : interlocuteur inconnu → retour à la messagerie' do
    get messagerie_conversation_url(to_user_slug: 0)
    assert_redirected_to messagerie_path
  end

  # ==================== TESTS CRITIQUES ====================

  test 'conversation : un utilisateur d’une autre organisation → retour à la messagerie (critique)' do
    get messagerie_conversation_url(to_user_slug: users(:manager_marseille).slug)

    assert_redirected_to messagerie_path
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'send_message : un interlocuteur du périmètre → le message est créé' do
    assert_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour',
        to_user_slug: @interlocutor_user.slug
      }
    end

    assert_response :success
  end

  test 'send_message : à soi-même → aucun message créé' do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour moi-même',
        to_user_slug: @current_user.slug
      }
    end

    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'send_message : vers un utilisateur d’une autre organisation → aucun message créé (critique)' do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'fuite ?',
        to_user_slug: users(:manager_marseille).slug
      }
    end
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'mark_as_read : un message qui m’est destiné → il est marqué lu' do
    message = Message.create!(message: 'Bonjour', from_id: @interlocutor_user.id, to_id: @current_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_not_nil message.reload.read_at
  end

  test 'mark_as_read : un message destiné à un autre → il reste non lu' do
    message = Message.create!(message: 'Pas pour moi', from_id: @current_user.id, to_id: @interlocutor_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_nil message.reload.read_at
  end

  test 'mark_as_read : un message déjà lu → sa date de lecture ne bouge pas' do
    message = Message.create!(message: 'Déjà lu', from_id: @interlocutor_user.id, to_id: @current_user.id,
                              read_at: 2.days.ago)
    lu_le = message.read_at

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_equal lu_le.to_i, message.reload.read_at.to_i
  end

  test 'search_contact : sans requête → les contacts du périmètre, sans soi-même' do
    post messagerie_search_contact_url

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), @current_user
  end

  test 'search_contact : requête sur le nom → les contacts correspondants' do
    post messagerie_search_contact_url, params: { query: 'Bond' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), users(:martin_technique_paris)
  end

  test 'search_contact : requête sur le prénom → les contacts correspondants' do
    post messagerie_search_contact_url, params: { query: 'James' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
  end
end
