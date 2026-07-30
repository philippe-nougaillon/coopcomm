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
end
