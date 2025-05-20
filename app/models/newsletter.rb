class Newsletter < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  private

    def slug_candidates
      [SecureRandom.uuid]
    end
end
