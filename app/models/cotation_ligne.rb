class CotationLigne < ApplicationRecord
  belongs_to :cotation
  belongs_to :prestation

  audited associated_with: :cotation

  validates :qté, :prix_ht, presence: true

  after_save    :refresh_cotation_total
  after_destroy :refresh_cotation_total

  private

  # Recalcule le total HT de la cotation à partir de ses lignes.
  def refresh_cotation_total
    return unless cotation && cotation.persisted? && !cotation.destroyed?

    cotation.update_column(:total_ht, cotation.cotation_lignes.sum(:total_ht))
  end
end
