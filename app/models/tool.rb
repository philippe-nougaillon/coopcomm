# frozen_string_literal: true

class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include PieceJointeValidable
  include PieceJointeAuditable

  audited
  
  belongs_to :organisation

  has_many :tool_interventions, dependent: :destroy
  has_many :interventions, through: :tool_interventions
  has_many :mouvements, dependent: :destroy
  has_many :documents, dependent: :destroy  
  
  has_one_attached :photo
  has_one_attached :document

  valide_image :photo
  valide_document :document

  normalizes :name, with: ->(name) { name.upcase.strip }

  validates :name, presence: true
  validates_uniqueness_of :name, scope: :organisation_id

  after_create :create_mouvement

  scope :ordered, -> { trié_par(:name, :description) }

  triable_par({ 'tools.name' => :texte }, puis: TriTextuel.expression('tools.description'))

  def self.icons
    {
      'Brouette': 'garden_cart',
      'Camionette': 'local_shipping',
      'Tracteur': 'agriculture',
      'Échelle': 'tools_ladder',
      'Perceuse': 'tools_power_drill'
    }
  end

  def self.indisponibles_ids(organisation_id, quand)
    quand = Time.zone.parse(quand)
    Intervention.joins(:tools)
                .where(organisation_id:)
                .where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:)
                .pluck('tools.id')
  end

  def disponible?(quand)
    interventions.where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:).empty?
  end

  def intervention_at(quand)
    quand = Time.zone.parse(quand)
    interventions.where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:).first
  end

  # etat : L = Libre, P = Panne, R = Réservé par current_user, I = réservé par un autre.
  # reservataire_id n'est renseigné que pour R et I.
  EtatJour = Struct.new(:etat, :reservataire_id)

  def get_etats_from_mouvements(first_date, last_date, current_user_id)
    results = []

    # Liste des dates entre la date de début et de fin
    days_range = (first_date..last_date).to_a

    est_en_panne = est_encore_en_panne_le(first_date)

    # On récupère les mouvements sur l'intervalle de temps
    mouvements = self.mouvements
                .where("DATE(date) BETWEEN DATE(?) AND DATE(?)", first_date, last_date) 

    # Pour chaque jour, noté J (day)
    days_range.each do |day|
      # On récupère les états et user_id des mouvements du jour J
      etats = mouvements.where(date: day).pluck(:état, :user_id).to_h
      
      # Valeur par défaut (Correspondant à rien)
      current_state = "L"
      reservataire_id = nil

      # Arrête la période de panne si fin_panne, pour éviter d'entrer dans la condition est_en_panne
      if etats.include?("fin_panne")
        est_en_panne = false
      end

      # Si l'outil est toujours en panne aujourd'hui
      if est_en_panne
        # Si l'outil est en panne, mais que le jour J est en fin de panne
        current_state = "P"
      else
        # Si des mouvements existent au jour J
        if etats["panne"].present? && etats["fin_panne"].blank?
          current_state = "P"
          est_en_panne = true
        elsif (mouvement_user_id = etats["réservé"].presence)
          reservataire_id = mouvement_user_id
          current_state = mouvement_user_id == current_user_id ? "R" : "I"
        end
      end

      results << EtatJour.new(current_state, reservataire_id)
    end

    return results
  end

  # On récupère la dernière panne en cours à la date donnée
  def est_encore_en_panne_le(date)
    mouvements.where('date <= ?', date)
              .where(état: ["panne", "fin_panne"])
              .order(date: :desc, id: :desc)
              .pick(:état) == "panne" # Prend la première panne trouvée
  end

  private

  def create_mouvement
    mouvements.create(état: 0, date: DateTime.now)
  end

  def slug_candidates
    [SecureRandom.uuid]
  end
end