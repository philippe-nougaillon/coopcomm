class Mouvement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :tool

  enum :état, {
    début: 0,
    fin: 1,
    in: 2,
    out: 3
  }

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
