class WikiPage < ApplicationRecord
  extend FriendlyId
  friendly_id :titre, use: :slugged

  has_rich_text :contenu

  enum catégorie: {
    documentation: 0,
    guide: 1,
    fiche: 2
  }

  def should_generate_new_friendly_id?
    titre_changed? || super
  end
end
