class CotationLigne < ApplicationRecord
  belongs_to :cotation
  belongs_to :prestation

  audited associated_with: :cotation

  # Le prix HT n'est jamais saisi : il provient toujours de la prestation choisie.
  before_validation :set_prix_from_prestation

  validates :qté, :prix_ht, presence: true

  after_save    :refresh_cotation_total
  after_destroy :refresh_cotation_total

  private

  def set_prix_from_prestation
    self.prix_ht = prestation.tarif if prestation
  end

  # Recalcule le total HT de la cotation à partir de ses lignes.
  def refresh_cotation_total
    return unless cotation && cotation.persisted? && !cotation.destroyed?

    cotation.update_column(:total_ht, cotation.cotation_lignes.sum(:total_ht))
  end
end
