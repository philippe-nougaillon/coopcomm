# frozen_string_literal: true

class Tool < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :tool_interventions, dependent: :destroy
  has_many :interventions, through: :tool_interventions
  has_many :mouvements, dependent: :destroy
  has_many :documents, dependent: :destroy
 
   accepts_nested_attributes_for :documents, allow_destroy: true,
    reject_if: proc { |attrs| attrs['fichier'].blank? && attrs['id'].blank? }

  has_one_attached :photo

  include PieceJointeValidable
  valide_piece_jointe :photo, types: PieceJointeValidable::IMAGES

  validates :name, presence: true
  validates_uniqueness_of :name, scope: :organisation_id

  after_create :create_mouvement

  scope :ordered, -> { order(Arel.sql("LOWER(unaccent(name)), LOWER(unaccent(description))")) }
  
  def self.icons
    { 'Brouette': 'garden_cart', 'Camionette': 'local_shipping', 'Tracteur': 'agriculture', 'Échelle': 'tools_ladder',
      'Perceuse': 'tools_power_drill' }
  end

  def disponible?(quand)
    interventions.where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:).empty?
  end

  def self.indisponibles_ids(organisation_id, quand)
    quand = Time.zone.parse(quand)
    Intervention.joins(:tools)
                .where(organisation_id:)
                .where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:)
                .pluck('tools.id')
  end

  def intervention_at(quand)
    quand = Time.zone.parse(quand)
    interventions.where(':quand BETWEEN interventions.début_prévue AND interventions.fin_prévue', quand:).first
  end

  def dernier_mouvement_a(heure)
    # TODO VU : kezako loaded ??
    # La fonction devrait disparaitre quand tools/show sera refait comme l'index
    # "loaded?" répond simplement à la question : « les mouvements ont-ils déjà été chargés en mémoire (dans un tableau Ruby), ou pas encore ? »

    if mouvements.loaded?
      # On filtre et on trie du plus récent au plus ancien
      mvs = mouvements.select { |m| m.date <= heure }.sort_by { |m| -m.date.to_i }

      # On cherche le dernier événement lié à une panne
      dernier_panne_event = mvs.find { |m| m.panne? || m.fin_panne? }

      # Si l'outil est cassé, on renvoie ce mouvement. Sinon, le mouvement classique.

    else
      # --- VERSION SQL (Fallback de sécurité) ---
      mvs = mouvements.where('date <= ?', heure).order(date: :desc)

      # On optimise la requête SQL pour chercher directement la dernière panne/fin_panne
      dernier_panne_event = mvs.where(état: %i[panne fin_panne]).first

    end
    return dernier_panne_event if dernier_panne_event&.panne?

    mvs.first
  end

  def get_etats_from_mouvements(first_date, last_date, current_user_id)
    # Stocke les lettres correspondants à l'état de l'outil sur l'intervalle de temps (L = Libre, P = Panne, R = Réservé, I = Indisponible)
    results = []

    # Liste des dates entre la date de début et de fin
    days_range = (first_date..(last_date)).to_a

    est_en_panne = est_encore_en_panne_le(first_date)

    # On récupère les mouvements sur l'intervalle de temps
    mouvements = self.mouvements
                  .where("DATE(date) BETWEEN DATE(?) AND DATE(?)", first_date, last_date)

    # Pour chaque jour, noté J (day)
    (days_range).each do |day|
      # On récupère les états et user_id des mouvements du jour J
      # On utilise where plutot que find car il peut exister un mouvement de panne et de réservation dans le même jour)
      etats = mouvements.where(date: day).pluck(:état, :user_id).to_h

      # Valeur par défaut (Correspondant à rien)
      current_state = "L"

      # Arrête la période de panne si fin_panne, pour éviter d'entrer dans la condition est_en_panne
      if etats.include?("fin_panne")
        est_en_panne = false
      end

      # Si l'outil est toujours en panne ajourd'hui
      if est_en_panne
        # Si l'outil est en panne, mais que le jour J est en fin de panne
        current_state = "P"
      else
        # Si des mouvements existent au jour J
        if etats.any?
          # Si une panne existe, on ouvre une période de panne
          if etats["panne"].present? && etats["fin_panne"].blank?
            current_state = "P"
            est_en_panne = true
          else
            # Sinon, l'outil est juste réservé par quelqu'un
            if mouvement_user_id = etats["réservé"].presence
              if mouvement_user_id == current_user_id
                current_state = "R"
              else
                current_state = "I"
              end
            end
          end
        end
      end

      results << current_state
    end

    return results
  end

  # On récupère la dernière panne en cours à la date donnée
  def est_encore_en_panne_le(date)
    self.mouvements
        .where('date <= ?', date)
        .where(état: ["panne", "fin_panne"])
        .order(date: :desc, id: :desc)
        .pick(:état) == "panne" # Permet de prendre
  end

  private

  def create_mouvement
    mouvements.create(état: 0, date: DateTime.now)
  end

  def slug_candidates
    [SecureRandom.uuid]
  end
end
