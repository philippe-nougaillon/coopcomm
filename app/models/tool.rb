class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :interventions

  validates_uniqueness_of :name, scope: :organisation_id

  scope :ordered, -> { order(:name, :description) }
  
  def disponible?
    self.interventions.where("NOW() BETWEEN interventions.début AND interventions.fin").empty?
  end

  def self.indisponibles_ids(organisation_id)
    Intervention.where(organisation_id:)
                .where("NOW() BETWEEN interventions.début AND interventions.fin")
                .pluck(:tool_id)
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
