class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :tool_interventions, dependent: :destroy
  has_many :interventions, through: :tool_interventions
  has_many :documents, dependent: :destroy
  
  accepts_nested_attributes_for :documents,
                                allow_destroy:true,
                                reject_if: lambda {|attributes| attributes['fichier'].blank?}

  validates :name, presence: true
  validates_uniqueness_of :name, scope: :organisation_id
  
  scope :ordered, -> { order(:name, :description) }
  
  def self.icons
    {'Brouette': 'garden_cart', 'Camionette': 'local_shipping', 'Tracteur': 'agriculture', 'Échelle': 'tools_ladder', 'Perçeuse': 'tools_power_drill' }
  end
  
  def disponible?(quand)
    self.interventions.where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:).empty?
  end

  def current_intervention
    self.interventions.where("NOW() BETWEEN interventions.début_prévue AND interventions.fin_prévue").first
  end

  def self.indisponibles_ids(organisation_id, quand)
    Intervention.joins(:tools)
                .where(organisation_id:)
                .where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:)
                .pluck('tools.id')
  end

  def intervention_at(quand)
    self.interventions.where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:).first
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
