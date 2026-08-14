# frozen_string_literal: true

require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  # Pas de tests à faire pour l'instant

  test 'nb_bad_words compte les insultes du message' do
    message = Message.new(message: 'Quel abruti, quel crétin !')

    assert_equal 2, message.nb_bad_words
  end

  test 'nb_bad_words vaut zéro sur un message correct' do
    assert_equal 0, Message.new(message: 'Bonjour, merci pour votre travail.').nb_bad_words
  end

  test 'un destinataire d’une autre organisation est refusé' do
    message = Message.new(from_user: users(:hidalgo), to_user: users(:manager_marseille), message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end
end
