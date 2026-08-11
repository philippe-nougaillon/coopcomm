class CommandeLigne < ApplicationRecord
  belongs_to :commande
  belongs_to :prestation

  audited associated_with: :commande

  validates :qté, :prix_ht, presence: true

  after_save    :refresh_commande_total
  after_destroy :refresh_commande_total

  private

  # Recalcule le total HT de la commande à partir de ses lignes.
  def refresh_commande_total
    return unless self.commande&.persisted? && !self.commande.destroyed?

    self.commande.update_column(:total_ht, self.commande.commande_lignes.sum(:total_ht))
  end
end