class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :interventions

  validates_uniqueness_of :name, scope: :organisation_id

  scope :ordered, -> { order(:name, :description) }
  
  def disponible?
    true
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
