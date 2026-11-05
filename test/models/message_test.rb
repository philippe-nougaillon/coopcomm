# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test 'les messages sont triés du plus récent au plus ancien' do
    ancien = Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Ancien',
                             created_at: 2.days.ago)
    récent = Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Récent',
                             created_at: 1.hour.ago)

    ordonnés = Message.ordered.to_a

    assert_operator ordonnés.index(récent), :<, ordonnés.index(ancien)
  end

  # ==================== TESTS CRITIQUES ====================
  # Les annonces visibles dérivent des services : les siens, tous ceux de l'organisation pour
  # l'administrateur, jamais ceux d'une autre organisation ; un adhérent n'en voit aucune.
  test "les annonces visibles d'un manager sont celles de ses services et les annonces générales de son organisation (critique)" do
    annonces = Message.annonces_pour(users(:hidalgo))

    assert_equal [messages(:annonce_service_paris), messages(:annonce_technique), messages(:annonce_générale_paris),
                  messages(:annonce_informatique)].sort_by(&:id), annonces.sort_by(&:id)
  end

  test "les annonces visibles d'un administrateur couvrent tous les services de son organisation (critique)" do
    annonces = Message.annonces_pour(users(:administrateur_paris))

    assert_equal [messages(:annonce_service_paris), messages(:annonce_technique), messages(:annonce_secretariat),
                  messages(:annonce_générale_paris), messages(:annonce_informatique),
                  messages(:annonce_piège)].sort_by(&:id), annonces.sort_by(&:id)
  end

  test "les annonces visibles d'un agent sont celles de son service et les annonces générales de son organisation (critique)" do
    annonces = Message.annonces_pour(users(:bond))

    assert_equal [messages(:annonce_technique), messages(:annonce_générale_paris)].sort_by(&:id), annonces.sort_by(&:id)
  end

  test 'un adhérent ne voit aucune annonce (critique)' do
    assert_empty Message.annonces_pour(users(:weil))
  end

  # ==================== /TESTS CRITIQUES ====================

  test "un message à un destinataire d'une autre organisation est refusé" do
    message = Message.new(from_user: users(:hidalgo), to_user: users(:manager_marseille), message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  test 'un message sans destinataire est refusé' do
    message = Message.new(from_user: users(:hidalgo), message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  # ==================== TESTS CRITIQUES ====================
  # Le filet sous le contrôleur vaut pour les trois genres : jamais d'annonce vers une autre organisation.
  test "une annonce à un service de l'organisation de l'auteur est acceptée (critique)" do
    assert Message.new(from_user: users(:hidalgo), genre: :annonce, to_id: services(:technique).id, message: 'x').valid?
  end

  test "une annonce à un service d'une autre organisation est refusée (critique)" do
    message = Message.new(from_user: users(:hidalgo), genre: :annonce, to_id: services(:service_marseille).id, message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  test 'une annonce à un service inexistant est refusée (critique)' do
    message = Message.new(from_user: users(:hidalgo), genre: :annonce, to_id: 0, message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  test "une annonce générale à l'organisation de l'auteur est acceptée (critique)" do
    assert Message.new(from_user: users(:administrateur_paris), genre: :annonce_générale,
                       to_id: organisations(:mairie_paris).id, message: 'x').valid?
  end

  test 'une annonce générale à une autre organisation est refusée (critique)' do
    message = Message.new(from_user: users(:administrateur_paris), genre: :annonce_générale,
                          to_id: organisations(:mairie_marseille).id, message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un message est diffusé sur le flux de chacun des deux interlocuteurs' do
    hidalgo = users(:hidalgo)
    weil = users(:weil)

    assert_broadcasts("chat_#{hidalgo.id}_with_#{weil.id}", 1) do
      assert_broadcasts("chat_#{weil.id}_with_#{hidalgo.id}", 1) do
        Message.create!(from_user: hidalgo, to_user: weil, message: 'Bonjour')
      end
    end
  end

  test "une annonce est diffusée sur le flux de son service et sur aucun flux de paire" do
    hidalgo = users(:hidalgo)
    technique = services(:technique)

    assert_no_broadcasts("chat_#{hidalgo.id}_with_#{technique.id}") do
      assert_broadcasts("annonces_service_#{technique.id}", 1) do
        Message.create!(from_user: hidalgo, genre: :annonce, to_id: technique.id, message: 'Réunion')
      end
    end
  end

  test "une annonce générale est diffusée sur le flux de l'organisation" do
    paris = organisations(:mairie_paris)

    assert_broadcasts("annonces_organisation_#{paris.id}", 1) do
      Message.create!(from_user: users(:administrateur_paris), genre: :annonce_générale, to_id: paris.id, message: 'Fermeture')
    end
  end

  # ==================== TESTS CRITIQUES ====================
  # Un identifiant de service peut être celui d'un utilisateur : seul le genre distingue un canal d'une paire.
  test "les annonces d'un service sont celles qui lui sont adressées, sans les messages portant son id (critique)" do
    assert_equal [messages(:annonce_technique)], Message.annonces_de(services(:technique)).to_a
  end

  test "les annonces générales d'une organisation sont celles qui lui sont adressées (critique)" do
    assert_equal [messages(:annonce_générale_paris)], Message.annonces_de(organisations(:mairie_paris)).to_a
  end

  # ==================== /TESTS CRITIQUES ====================

  test "le flux d'annonces d'un service porte son id" do
    assert_equal "annonces_service_#{services(:technique).id}", Message.flux_annonces(services(:technique))
  end

  test "le flux d'annonces générales porte l'id de l'organisation" do
    assert_equal "annonces_organisation_#{organisations(:mairie_paris).id}", Message.flux_annonces(organisations(:mairie_paris))
  end

  test 'la modération remplace les insultes du message et laisse le reste intact' do
    message = Message.new(message: 'Quel abruti, merci quand même')

    assert_equal 'Quel 🌼🌼🌼, merci quand même', message.moderation
  end

  test 'la modération rend un message correct tel quel' do
    assert_equal 'Bonjour, merci', Message.new(message: 'Bonjour, merci').moderation
  end

  test 'les insultes sont comptées une fois par occurrence dans le message' do
    message = Message.new(message: 'Quel abruti, quel crétin !')

    assert_equal 2, message.nb_bad_words
  end

  test 'un message correct compte zéro insulte' do
    assert_equal 0, Message.new(message: 'Bonjour, merci pour votre travail.').nb_bad_words
  end

  test "le destinataire d'un message est un utilisateur" do
    assert_equal users(:bond), messages(:one).destinataire
  end

  test "le destinataire d'une annonce est un service" do
    assert_equal services(:technique), messages(:annonce_technique).destinataire
  end

  test "le destinataire d'une annonce générale est une organisation" do
    assert_equal organisations(:mairie_paris), messages(:annonce_générale_paris).destinataire
  end
end
