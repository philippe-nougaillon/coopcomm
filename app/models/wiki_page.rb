class WikiPage < ApplicationRecord
  extend FriendlyId
  friendly_id :titre, use: :slugged
  
  has_rich_text :contenu
  
  include PgSearch::Model
  include Discard::Model
  
  pg_search_scope :search_titre_and_contenu,
                  against: :titre,
                  associated_against: {
                    rich_text_content: [:body]
                  },
                  using: {
                    tsearch: { prefix: true } # Recherche avec préfixes pour autocomplétion
                  }
                  
  has_one :rich_text_content, -> { where(name: "contenu") }, class_name: "ActionText::RichText", as: :record

  enum catégorie: {
    blog: 0,
    guide: 1,
    fiches: 2
  }

  default_scope -> { kept } # Sans les discarded

  def should_generate_new_friendly_id?
    titre_changed? || super
  end
end
