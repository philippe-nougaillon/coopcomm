# frozen_string_literal: true

class Prestation < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :cotation_lignes, dependent: :restrict_with_error
  has_many :commande_lignes, dependent: :restrict_with_error
  has_many :facture_lignes, dependent: :restrict_with_error


  validates :code, :libellé, :tarif, presence: true
  validates :code, uniqueness: { scope: :organisation_id, case_sensitive: false }

  normalizes :code,           with: ->(value) { value.to_s.upcase }
  normalizes :catégorie,      with: ->(value) { value.to_s.upcase }
  normalizes :sous_catégorie, with: ->(value) { value.to_s.upcase }
  normalizes :unité,          with: ->(value) { value.to_s.strip.presence }

  scope :ordered, -> { trié_par(:code, :libellé) }

  triable_par 'prestations.code' => :texte,
              'prestations.libellé' => :texte,
              'prestations.catégorie' => :texte,
              'prestations.sous_catégorie' => :texte,
              'prestations.unité' => :texte,
              'prestations.tarif' => :brut

  def display_name
    "#{code} → #{libellé} (#{tarif} € HT)"
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
