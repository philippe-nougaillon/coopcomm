# frozen_string_literal: true

require 'test_helper'

class DiscussionsRecentesTest < ActiveSupport::TestCase
  setup do
    @administrateur = users(:administrateur_paris)
    Message.create!(from_user: users(:weil), to_user: @administrateur, message: 'Déjà lu',
                    read_at: Time.zone.local(2026, 3, 1, 8, 30), created_at: Time.zone.local(2026, 3, 1, 8))
    Message.create!(from_user: users(:weil), to_user: @administrateur, message: 'Bonjour',
                    created_at: Time.zone.local(2026, 3, 1, 9))
    @réponse_à_weil = Message.create!(from_user: @administrateur, to_user: users(:weil), message: 'Réponse',
                                      created_at: Time.zone.local(2026, 3, 2, 9))
    Message.create!(from_user: users(:martin_technique_paris), to_user: @administrateur, message: 'Premier',
                    created_at: Time.zone.local(2026, 3, 3, 9))
    @dernier_de_martin = Message.create!(from_user: users(:martin_technique_paris), to_user: @administrateur,
                                         message: 'Second', created_at: Time.zone.local(2026, 3, 3, 10))
  end

  test 'les discussions comptent un interlocuteur chacune, de la plus récente à la plus ancienne' do
    assert_equal [users(:martin_technique_paris), users(:weil)],
                 DiscussionsRecentes.call(@administrateur).map { |discussion| discussion[:user] }
  end

  test 'une discussion porte le dernier message échangé, envoyé ou reçu' do
    assert_equal [@dernier_de_martin, @réponse_à_weil],
                 DiscussionsRecentes.call(@administrateur).map { |discussion| discussion[:last_message] }
  end

  # ==================== TESTS CRITIQUES ====================
  # Un identifiant de service peut être celui d'un utilisateur : sans le genre, une annonce
  # passerait pour un message échangé avec lui.
  test 'les discussions ignorent les annonces portant l’id de l’utilisateur (critique)' do
    assert_equal [@administrateur],
                 DiscussionsRecentes.call(users(:martin_technique_paris)).map { |discussion| discussion[:user] }
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'les discussions écartent un interlocuteur désactivé' do
    users(:weil).discard

    assert_equal [users(:martin_technique_paris)],
                 DiscussionsRecentes.call(@administrateur).map { |discussion| discussion[:user] }
  end

  test 'les discussions écartent un interlocuteur qui ne partage plus aucun service (critique)' do
    users(:martin_technique_paris).update!(service_ids: [services(:secretariat).id])

    assert_equal [users(:weil)], DiscussionsRecentes.call(@administrateur).map { |discussion| discussion[:user] }
  end

  test 'une discussion compte les messages de l’interlocuteur restés non lus' do
    assert_equal [2, 1], DiscussionsRecentes.call(@administrateur).map { |discussion| discussion[:unread_count] }
  end
end
