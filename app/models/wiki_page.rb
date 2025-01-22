class WikiPage < ApplicationRecord
  extend FriendlyId
  friendly_id :titre, use: :slugged
  
  has_rich_text :contenu
  
  include PgSearch::Model
  
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
    documentation: 0,
    guide: 1,
    fiche: 2
  }

  def should_generate_new_friendly_id?
    titre_changed? || super
  end

  def icone_catégorie
    icone = case self.catégorie
      when 'documentation' then 'description'
      when 'guide' then 'help'
      when 'fiche' then 'assignment'
    end
    icone
  end
end
