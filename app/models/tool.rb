class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :tool_interventions, dependent: :destroy
  has_many :interventions, through: :tool_interventions
  has_many :documents, dependent: :destroy
  has_many :mouvements, dependent: :destroy
  
  has_one_attached :photo

  accepts_nested_attributes_for :documents,
                                allow_destroy:true,
                                reject_if: lambda {|attributes| attributes['fichier'].blank?}

  validates :name, presence: true
  validates_uniqueness_of :name, scope: :organisation_id

  after_create :create_mouvement
  
  scope :ordered, -> { order(:name, :description) }
  
  def self.icons
    {'Brouette': 'garden_cart', 'Camionette': 'local_shipping', 'Tracteur': 'agriculture', 'Échelle': 'tools_ladder', 'Perçeuse': 'tools_power_drill' }
  end
  
  def disponible?(quand)
    self.interventions.where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:).empty?
  end

  def self.indisponibles_ids(organisation_id, quand)
    quand = Time.zone.parse(quand)
    Intervention.joins(:tools)
                .where(organisation_id:)
                .where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:)
                .pluck('tools.id')
  end

  def intervention_at(quand)
    quand = Time.zone.parse(quand)
    self.interventions.where(":quand BETWEEN interventions.début_prévue AND interventions.fin_prévue", quand:).first
  end

  def dernier_mouvement_a(heure)
    # Si les mouvements ont été préchargés en mémoire par le contrôleur (via includes)
    if mouvements.loaded?
      # On filtre le tableau en mémoire
      mouvements.select { |m| m.date <= heure }.max_by(&:date)
    else
      # Fallback SQL de sécurité si on appelle la méthode ailleurs sans "includes"
      mouvements.where("date <= ?", heure).order(date: :desc).first
    end
  end

  private

  def create_mouvement
    self.mouvements.create(état: 0, date: DateTime.now)
  end

  def slug_candidates
    [SecureRandom.uuid]
  end
end
