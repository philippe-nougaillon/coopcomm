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

  # ==================== TESTS CRITIQUES ====================
  # Un identifiant de service peut être celui d'un utilisateur : sans le genre, une annonce
  # passerait pour un message reçu. Les canaux proposés dérivent des services, selon le rôle.
  test 'les discussions récentes ignorent les annonces portant l’id de l’utilisateur (critique)' do
    sign_in users(:martin_technique_paris)

    get messagerie_url

    assert_empty assigns(:recent_conversations)
    assert_empty assigns(:unread_counts)
  end

  test 'la sidebar propose à un manager les annonces de ses seuls services (critique)' do
    get messagerie_url

    assert_equal [services(:informatique), services(:service_paris), services(:technique)], assigns(:services_annonces).to_a
  end

  test 'la sidebar propose à un administrateur les annonces de tous les services de son organisation (critique)' do
    sign_in users(:administrateur_paris)

    get messagerie_url

    assert_includes assigns(:services_annonces), services(:secretariat)
    assert_not_includes assigns(:services_annonces), services(:service_marseille)
  end

  test 'la sidebar ne propose aucune annonce à un adhérent (critique)' do
    sign_in users(:weil)

    get messagerie_url

    assert_nil assigns(:services_annonces)
  end

  # ==================== /TESTS CRITIQUES ====================

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

  test 'une conversation ignore les annonces portant l’id de l’interlocuteur (critique)' do
    get messagerie_conversation_url(users(:martin_technique_paris).slug)

    assert_empty assigns(:messages)
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

  test 'une annonce portant l’id du lecteur reste sans date de lecture (critique)' do
    sign_in users(:martin_technique_paris)

    post messagerie_mark_as_read_url, params: { id: messages(:annonce_piège).id }

    assert_response :success
    assert_nil messages(:annonce_piège).reload.read_at
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

  test 'les annonces générales sont affichées avec succès' do
    get messagerie_annonces_url

    assert_response :success
  end

  test 'les annonces d’un service sont affichées avec succès' do
    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert_response :success
  end

  test 'les annonces d’un service inconnu ramènent à la messagerie' do
    get messagerie_annonces_url(service_slug: 'inconnu')

    assert_redirected_to messagerie_path
  end

  test 'la page des annonces d’un service écoute le flux de ce service' do
    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert_equal "annonces_service_#{services(:technique).id}", assigns(:flux)
  end

  test 'un manager peut publier dans les annonces de son service' do
    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert assigns(:peut_ecrire)
  end

  test 'un manager ne peut pas publier d’annonce générale' do
    get messagerie_annonces_url

    assert_not assigns(:peut_ecrire)
  end

  test 'un agent ne peut pas publier dans les annonces de son service' do
    sign_in users(:bond)

    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert_not assigns(:peut_ecrire)
  end

  # ==================== TESTS CRITIQUES ====================
  # Un canal d'annonces est un service : chacun ne lit que les siens, l'administrateur tous ceux de
  # son organisation, jamais ceux d'une autre organisation ; un adhérent n'en lit aucun.
  test 'les annonces générales affichées sont celles de l’organisation, sans celles d’une autre (critique)' do
    get messagerie_annonces_url

    assert_equal [messages(:annonce_générale_paris)], assigns(:messages).to_a
  end

  test 'les annonces d’un service affichées sont les siennes, sans les messages portant son id (critique)' do
    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert_equal [messages(:annonce_technique)], assigns(:messages).to_a
  end

  test 'les annonces d’un service d’une autre organisation ramènent à la messagerie (critique)' do
    get messagerie_annonces_url(service_slug: services(:service_marseille).slug)

    assert_redirected_to messagerie_path
  end

  test 'les annonces d’un service dont le manager n’est pas membre sont refusées (critique)' do
    get messagerie_annonces_url(service_slug: services(:secretariat).slug)

    assert_redirected_to root_path
    assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
  end

  test 'les annonces d’un service de son organisation sont affichées à un administrateur qui n’en est pas membre (critique)' do
    sign_in users(:administrateur_paris)

    get messagerie_annonces_url(service_slug: services(:secretariat).slug)

    assert_response :success
  end

  test 'les annonces sont refusées à un adhérent (critique)' do
    sign_in users(:weil)

    get messagerie_annonces_url(service_slug: services(:technique).slug)

    assert_redirected_to root_path
  end

  test 'une annonce publiée par un manager dans son service est créée (critique)' do
    assert_difference('Message.annonce.count') do
      post messagerie_send_annonce_url, params: { message: 'Réunion vendredi', service_slug: services(:technique).slug }
    end

    assert_response :success
    annonce = Message.annonce.find_by(message: 'Réunion vendredi')
    assert_equal [@current_user.id, services(:technique).id], [annonce.from_id, annonce.to_id]
  end

  test 'une annonce générale publiée par un administrateur est créée (critique)' do
    sign_in users(:administrateur_paris)

    assert_difference('Message.annonce_générale.count') do
      post messagerie_send_annonce_url, params: { message: 'Fermeture le 15' }
    end

    assert_equal organisations(:mairie_paris).id, Message.annonce_générale.find_by(message: 'Fermeture le 15').to_id
  end

  test 'une annonce générale publiée par un manager n’est pas créée (critique)' do
    assert_no_difference('Message.count') do
      post messagerie_send_annonce_url, params: { message: 'Fermeture le 15' }
    end

    assert_redirected_to root_path
  end

  test 'une annonce publiée par un manager dans un service dont il n’est pas membre n’est pas créée (critique)' do
    assert_no_difference('Message.count') do
      post messagerie_send_annonce_url, params: { message: 'Permanence', service_slug: services(:secretariat).slug }
    end

    assert_redirected_to root_path
  end

  test 'une annonce publiée par un agent n’est pas créée (critique)' do
    sign_in users(:bond)

    assert_no_difference('Message.count') do
      post messagerie_send_annonce_url, params: { message: 'Réunion', service_slug: services(:technique).slug }
    end

    assert_redirected_to root_path
  end

  test 'une annonce publiée dans un service d’une autre organisation n’est pas créée (critique)' do
    assert_no_difference('Message.count') do
      post messagerie_send_annonce_url, params: { message: 'fuite ?', service_slug: services(:service_marseille).slug }
    end

    assert_redirected_to messagerie_path
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une annonce vide n’est pas créée' do
    assert_no_difference('Message.count') do
      post messagerie_send_annonce_url, params: { message: '', service_slug: services(:technique).slug }
    end

    assert_response :success
  end
end
