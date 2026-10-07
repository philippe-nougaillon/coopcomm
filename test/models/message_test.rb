# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  test 'les messages sont triés du plus récent au plus ancien' do
    ancien = Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Ancien',
                             created_at: 2.days.ago)
    récent = Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Récent',
                             created_at: 1.hour.ago)

    ordonnés = Message.ordered.to_a

    assert_operator ordonnés.index(récent), :<, ordonnés.index(ancien)
  end

  test "un message à un destinataire d'une autre organisation est refusé" do
    message = Message.new(from_user: users(:hidalgo), to_user: users(:manager_marseille), message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
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
end
