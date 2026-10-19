# frozen_string_literal: true

require 'test_helper'

class MessagerieControllerTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = users(:hidalgo)

    @interlocutor_user = users(:bond)

    sign_in @current_user
  end

  test 'la messagerie est affichée avec succès' do
    get messagerie_url
    assert_response :success
  end

  test 'les contacts de la messagerie ne proposent que les comptes actifs' do
    désactivé = users(:agent_discarded_paris)

    get messagerie_url
    assert_not_includes assigns(:users), désactivé

    désactivé.undiscard

    get messagerie_url
    assert_includes assigns(:users), désactivé
  end

  test 'une conversation est affichée avec succès' do
    get messagerie_conversation_url(@interlocutor_user.slug)
    assert_response :success
  end

  test 'une conversation avec soi-même ramène à la messagerie' do
    get messagerie_conversation_url(@current_user.slug)
    assert_redirected_to messagerie_path
  end

  test 'une conversation avec un interlocuteur inconnu ramène à la messagerie' do
    get messagerie_conversation_url(to_user_slug: 0)
    assert_redirected_to messagerie_path
  end

  test 'une conversation avec un agent est affichée avec succès' do
    get messagerie_conversation_url(users(:bond).slug)

    assert_response :success
  end

  test 'une conversation avec un manager est affichée avec succès' do
    get messagerie_conversation_url(users(:manager_paris).slug)

    assert_response :success
  end

  test 'une conversation avec un administrateur est affichée avec succès' do
    get messagerie_conversation_url(users(:administrateur_paris).slug)

    assert_response :success
  end

  test 'une conversation avec un adhérent est affichée avec succès' do
    get messagerie_conversation_url(users(:patrick_adherent_paris).slug)

    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'une conversation avec un utilisateur d’une autre organisation ramène à la messagerie (critique)' do
    get messagerie_conversation_url(to_user_slug: users(:manager_marseille).slug)

    assert_redirected_to messagerie_path
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un message envoyé à un interlocuteur est créé' do
    assert_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour',
        to_user_slug: @interlocutor_user.slug
      }
    end

    assert_response :success
  end

  test 'un message envoyé à soi-même n’est pas créé' do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'Bonjour moi-même',
        to_user_slug: @current_user.slug
      }
    end

    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un message envoyé à un utilisateur d’une autre organisation n’est pas créé (critique)' do
    assert_no_difference('Message.count') do
      post messagerie_send_message_url, params: {
        message: 'fuite ?',
        to_user_slug: users(:manager_marseille).slug
      }
    end
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un message dont on est le destinataire est marqué lu' do
    message = Message.create!(message: 'Bonjour', from_id: @interlocutor_user.id, to_id: @current_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_not_nil message.reload.read_at
  end

  test 'un message destiné à un autre utilisateur reste non lu' do
    message = Message.create!(message: 'Pas pour moi', from_id: @current_user.id, to_id: @interlocutor_user.id)

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_nil message.reload.read_at
  end

  test 'un message déjà lu garde sa date de lecture' do
    message = Message.create!(message: 'Déjà lu', from_id: @interlocutor_user.id, to_id: @current_user.id,
                              read_at: 2.days.ago)
    lu_le = message.read_at

    post messagerie_mark_as_read_url, params: { id: message.id }

    assert_response :success
    assert_equal lu_le.to_i, message.reload.read_at.to_i
  end

  test 'la recherche de contact sans requête propose les contacts, sans soi-même' do
    post messagerie_search_contact_url

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), @current_user
  end

  test 'la recherche de contact par nom ne propose que les contacts correspondants' do
    post messagerie_search_contact_url, params: { query: 'Bond' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
    assert_not_includes assigns(:users), users(:martin_technique_paris)
  end

  test 'la recherche de contact par prénom propose les contacts correspondants' do
    post messagerie_search_contact_url, params: { query: 'James' }

    assert_response :success
    assert_includes assigns(:users), @interlocutor_user
  end

  test 'la recherche de contact ne propose que les comptes actifs' do
    désactivé = users(:agent_discarded_paris)

    post messagerie_search_contact_url, params: { query: désactivé.nom }
    assert_not_includes assigns(:users), désactivé

    désactivé.undiscard

    post messagerie_search_contact_url, params: { query: désactivé.nom }
    assert_includes assigns(:users), désactivé
  end
end
