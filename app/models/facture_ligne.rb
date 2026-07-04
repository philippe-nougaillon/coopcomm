class FactureLigne < ApplicationRecord
  belongs_to :facture
  belongs_to :prestation

  audited associated_with: :facture

  # Le prix HT n'est jamais saisi : il provient toujours de la prestation choisie.
  before_validation :set_prix_from_prestation

  validates :qté, :prix_ht, presence: true

  after_save    :refresh_facture_total
  after_destroy :refresh_facture_total

  private

  def set_prix_from_prestation
    self.prix_ht = self.prestation.tarif if self.prestation.present?
  end

  # Recalcule le total HT de la facture à partir de ses lignes.
  def refresh_facture_total
    return unless self.facture&.persisted? && !self.facture.destroyed?

    self.facture.update_column(:total_ht, self.facture.facture_lignes.sum(:total_ht))
  end
end