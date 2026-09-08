# frozen_string_literal: true

class WikiPage < ApplicationRecord
  extend FriendlyId
  friendly_id :titre, use: :slugged

  include PieceJointeValidable
  include PieceJointeAuditable

  audited

  belongs_to :user
  has_rich_text :contenu
  has_one_attached :document
  has_one_attached :photo

  valide_image :photo
  valide_document :document

  include PgSearch::Model
  include Discard::Model

  pg_search_scope :search_titre_and_contenu,
                  against: [:titre, :sous_titre],
                  associated_against: {
                    rich_text_content: [:body]
                  },
                  using: {
                    tsearch: { prefix: true } # Recherche avec préfixes pour autocomplétion
                  }

  has_one :rich_text_content, -> { where(name: 'contenu') }, class_name: 'ActionText::RichText', as: :record

  enum :catégorie, {
    blog: 0,
    guide: 1,
    faq: 2
  }

  default_scope -> { kept.order(épinglée: :desc).order(:poids).order(updated_at: :desc) }

  scope :by_categorie, ->(categorie) { where(catégorie: categorie) }

  # Retourne les wiki pages selon le role de l'utilisateur
  def self.by_role_for(user)
    case user&.rôle
    when 'manager', 'administrateur'
      WikiPage.all
    when 'adhérent'
      WikiPage.where(publiée: true)
    when 'agent'
      WikiPage.where(publiée: true, private: false)
    else
      WikiPage.where(publiée: true, private: false)
    end
  end

  def should_generate_new_friendly_id?
    titre_changed? || super
  end
end
