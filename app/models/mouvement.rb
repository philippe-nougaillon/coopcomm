class Mouvement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :tool
  belongs_to :intervention, optional: true

  scope :ordered, -> { order(date: :desc) }

  enum :état, {
    achat: 0,
    réforme: 1,
    entrée: 2,
    sortie: 3,
    révision: 4,
    panne: 5
  }

  def style
    case self.état
    when 'début'
      'primary'
    when 'fin'
      'secondary'
    when 'entrée'
      'success'
    when 'sortie'
      'error'
    when 'révision', 'panne'
      'warning'
    else
      'info'
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
