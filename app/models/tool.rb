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
    if mouvements.loaded?
      # On filtre et on trie du plus récent au plus ancien
      mvs = mouvements.select { |m| m.date <= heure }.sort_by { |m| -m.date.to_i }
      
      # On cherche le dernier événement lié à une panne
      dernier_panne_event = mvs.find { |m| m.panne? || m.fin_panne? }
      
      # Si l'outil est cassé, on renvoie ce mouvement. Sinon, le mouvement classique.
      return dernier_panne_event if dernier_panne_event&.panne?
      mvs.first

    else
      # --- VERSION SQL (Fallback de sécurité) ---
      mvs = mouvements.where("date <= ?", heure).order(date: :desc)
      
      # On optimise la requête SQL pour chercher directement la dernière panne/fin_panne
      dernier_panne_event = mvs.where(état: [:panne, :fin_panne]).first
      
      return dernier_panne_event if dernier_panne_event&.panne?
      mvs.first
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
