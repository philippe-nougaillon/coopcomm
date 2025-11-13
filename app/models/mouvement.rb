class Mouvement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :tool
  belongs_to :intervention, optional: true

  enum :état, {
    début: 0,
    fin: 1,
    entrée: 2,
    sortie: 3,
    révision: 4,
    panne: 5,
    reforme: 6
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
