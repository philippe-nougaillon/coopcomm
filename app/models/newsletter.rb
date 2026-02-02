class Newsletter < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  validates :email, uniqueness: true

  private

    def slug_candidates
      [SecureRandom.uuid]
    end
end
