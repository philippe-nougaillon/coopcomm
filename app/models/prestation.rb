# frozen_string_literal: true

class Prestation < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :cotation_lignes, dependent: :restrict_with_error
  has_many :commande_lignes, dependent: :restrict_with_error
  has_many :facture_lignes, dependent: :restrict_with_error

  # Unité facturée pré-remplie à « H » (heure) à la création ; reste modifiable.
  # Le défaut ne s'applique qu'aux nouveaux enregistrements ; les prestations
  # déjà en base conservent leur valeur (y compris vide).
  attribute :unité, :string, default: "H"

  validates :code, :libellé, :tarif, presence: true
  validates :code, uniqueness: { scope: :organisation_id, case_sensitive: false }

  normalizes :code,           with: ->(value) { value.to_s.upcase }
  normalizes :catégorie,      with: ->(value) { value.to_s.upcase }
  normalizes :sous_catégorie, with: ->(value) { value.to_s.upcase }

  scope :ordered, -> { order(:code) }

  def display_name
    "#{code} → #{libellé} (#{tarif} € HT)"
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
