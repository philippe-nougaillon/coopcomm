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

  def get_mouvements_for_next_14_days
    self.mouvements
                  .where("DATE(date) BETWEEN DATE(?) AND DATE(?)", DateTime.now, DateTime.now+13)
  end

  def get_etats_from_mouvements
    mouvements = get_mouvements_for_next_14_days
    
    days_range = (Date.today..(Date.today + 13.days)).to_a

    planning = []

    est_en_panne = self.en_panne

    # Pour chaque jour, noté J+X
    (days_range).each do |day|
      etats = mouvements.where(date: day).pluck(:état) # Where car il peut exister un mouvement de panne et de réservation dans le même jour

      # Si l'outil est toujours en panne ajourd'hui
      if est_en_panne
        # Si l'outil est en panne, mais que le jour J+X est en fin de panne
        if etats.include?("fin_panne")
          planning << "V"
          est_en_panne = false
        # Sinon on considère qu'il est toujours en panne le jour J+X
        else
          planning << "N"
        end
      else
        # Si des mouvements existent au jour J+X
        if etats.any?
          # Si une panne existe, on ouvre une période de panne
          if etats.include?("panne")
            planning << "N"
            est_en_panne = true
          # Sinon, l'outil est juste réservé par quelqu'un
          else
            planning << "B|R"
          end
        # Sinon, l'outil est disponible ce jour
        else
          planning << "V"
        end
      end
    end

    planning
  end

  private

  def create_mouvement
    self.mouvements.create(état: 0, date: DateTime.now)
  end

  def slug_candidates
    [SecureRandom.uuid]
  end
end
