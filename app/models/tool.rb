class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :interventions

  validates_uniqueness_of :name, scope: :organisation_id

  scope :ordered, -> { order(:name, :description) }

  def self.icons
    {'Brouette': 'garden_cart', 'Camionette': 'local_shipping', 'Tracteur': 'agriculture', 'Échelle': 'tools_ladder', 'Perçeuse': 'tools_power_drill' }
  end
  
  def disponible?(quand)
    self.interventions.where(":quand BETWEEN interventions.début AND interventions.fin", quand:).empty?
  end

  def current_intervention
    self.interventions.where("NOW() BETWEEN interventions.début AND interventions.fin").first
  end

  def self.indisponibles_ids(organisation_id, quand)
    Intervention.where(organisation_id:)
                .where(":quand BETWEEN interventions.début AND interventions.fin", quand:)
                .pluck(:tool_id)
  end

  def intervention_at(quand)
    self.interventions.where(":quand BETWEEN interventions.début AND interventions.fin", quand:).first
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
