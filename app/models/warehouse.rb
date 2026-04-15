class Warehouse < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  acts_as_taggable_on :tags

  audited

  belongs_to :organisation

  validates :address, :latitude, :longitude, presence: true

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
