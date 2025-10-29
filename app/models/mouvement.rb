class Mouvement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :tool
  belongs_to :intervention, optional: true

  enum :état, {
    début: 0,
    fin: 1,
    in: 2,
    out: 3
  }

  def style
    case self.état
    when 'début'
      'primary'
    when 'fin'
      'secondary'
    when 'in'
      'success'
    when 'out'
      'error'
    else
      'warning'
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
