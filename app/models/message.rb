# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :from_user, class_name: 'User', foreign_key: :from_id
  belongs_to :to_user, class_name: 'User', foreign_key: :to_id

  scope :ordered, -> { order(created_at: :desc) }

  validates :message, presence: true
  # Filet de sécurité sous le contrôleur : jamais de message inter-organisations
  validate :interlocuteurs_de_la_même_organisation

  def interlocuteurs_de_la_même_organisation
    return if from_user.nil? || to_user.nil?
    return if from_user.organisation == to_user.organisation

    errors.add(:base, 'Destinataire injoignable')
  end

  after_create_commit lambda {
    broadcast_append_to "chat_#{from_id}_with_#{to_id}",
                        partial: 'messagerie/message',
                        locals: { message: self, my_message: true },
                        target: 'chat-messages-container'
  }

  after_create_commit lambda {
    broadcast_append_to "chat_#{to_id}_with_#{from_id}",
                        partial: 'messagerie/message',
                        locals: { message: self, my_message: false },
                        target: 'chat-messages-container'
  }

  def self.bad_words_regex
    bad_words = %w[
      connard connasse con enfoirée enfoiré putain merde couille
      salope pute enculée enculé bâtarde bâtard
      trouducul trouduc merde chiant chieuse
      abrutie abruti débile crétine crétin fuck-you
      emmerdeuse emmerdeur casse-couilles
      glandu gland trou-du-cul bordel Teube Teubê 
      bouffonne bouffon baltringue fumier ordure foutre
    ]

    /\b(#{bad_words.join('|')})\b/i
  end

  def moderation
    message.gsub(Message.bad_words_regex, '🌼🌼🌼')
  end

  def nb_bad_words
    message.scan(Message.bad_words_regex).size
  end
end
