# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :from_user, class_name: 'User', foreign_key: :from_id
  belongs_to :to_user, class_name: 'User', foreign_key: :to_id, optional: true

  # Le genre dit ce que désigne to_id : un utilisateur, un service ou l'organisation entière
  enum :genre, { message: 0, annonce: 1, annonce_générale: 2 }

  scope :ordered, -> { order(created_at: :desc) }
  scope :annonces_pour, lambda { |user|
    next none if user.adhérent?

    annonce.where(to_id: user.get_services_by_role).or(annonce_générale.where(to_id: user.organisation_ids))
  }

  validates :message, presence: true
  # Filet de sécurité sous le contrôleur : jamais de message inter-organisations
  validate :destinataire_de_la_même_organisation

  def destinataire_de_la_même_organisation
    return if from_user.nil?

    organisation = annonce_générale? ? destinataire : destinataire&.organisation
    return if organisation.present? && organisation == from_user.organisation

    errors.add(:base, 'Destinataire injoignable')
  end

  after_create_commit lambda {
    broadcast_append_to "chat_#{from_id}_with_#{to_id}",
                        partial: 'messagerie/message',
                        locals: { message: self, my_message: true },
                        target: 'chat-messages-container'
  }, if: :message?

  after_create_commit lambda {
    broadcast_append_to "chat_#{to_id}_with_#{from_id}",
                        partial: 'messagerie/message',
                        locals: { message: self, my_message: false },
                        target: 'chat-messages-container'
  }, if: :message?

  # Une annonce arrive dans la même forme chez tous ; l'auteur remet la sienne de son côté (conversation_controller.js)
  after_create_commit lambda {
    broadcast_append_to Message.flux_annonces(destinataire),
                        partial: 'messagerie/message',
                        locals: { message: self, my_message: false },
                        target: 'chat-messages-container'
  }, unless: :message?

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

  def self.annonces_de(cible)
    cible.is_a?(Service) ? annonce.where(to_id: cible.id) : annonce_générale.where(to_id: cible.id)
  end

  def self.flux_annonces(cible)
    "annonces_#{cible.model_name.singular}_#{cible.id}"
  end

  def moderation
    message.gsub(Message.bad_words_regex, '🌼🌼🌼')
  end

  def nb_bad_words
    message.scan(Message.bad_words_regex).size
  end

  def destinataire
    case genre
    when 'annonce' then Service.find_by(id: to_id)
    when 'annonce_générale' then Organisation.find_by(id: to_id)
    else to_user
    end
  end
end
