# frozen_string_literal: true

class Mouvement < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :tool
  has_one :organisation, through: :tool
  belongs_to :user
  belongs_to :intervention, optional: true

  scope :ordered, -> { order(date: :desc) }

  enum :état, {
    entrée: 0,
    sortie: 1,
    panne: 2,
    fin_panne: 3,
    réservé: 4
  }

  validates :date, presence: true
  validate :coherence_panne, if: :panne?
  validate :coherence_fin_panne, if: :fin_panne?

  after_create :avertir_reservations_futures, if: :panne?
  after_save :nettoyer_reservations_pendant_panne, if: :fin_panne?

  def style
    case état
    when 'début'
      'primary'
    when 'fin'
      'secondary'
    when 'entrée'
      'success'
    when 'sortie'
      'error'
    when 'révision', 'panne'
      'warning'
    else
      'info'
    end
  end

  def resolue?
    return false unless panne?

    # On vérifie s'il y a un événement "fin_panne" postérieur à cette panne
    if tool.mouvements.loaded?
      tool.mouvements.any? { |m| m.fin_panne? && m.date > date }
    else
      tool.mouvements.where(état: :fin_panne).where('date > ?', date).exists?
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

  # TODO VU : vérifier que 'mouvements.date & état' sont indexés car de nombreuses requêtes sont basées dessus...
  # Seul "date" est indexé

  # Vérifie qu'on ne déclare pas une panne alors que l'outil est déjà en panne.
  def coherence_panne
    event_precedent, event_suivant = evenements_panne_voisins

    errors.add(:état, "Impossible : l'outil est déjà en panne à ce moment-là.") if event_precedent&.panne?

    return unless event_suivant&.panne?

    errors.add(:état, 'Impossible : une autre panne est déjà déclarée juste après sans avoir été réparée.')
  end

  # Vérifie qu'on ne déclare pas une fin de panne alors que l'outil ne l'est pas.
  def coherence_fin_panne
    event_precedent, event_suivant = evenements_panne_voisins

    if event_precedent.nil? || event_precedent.fin_panne?
      errors.add(:état, "Impossible : l'outil n'était pas déclaré en panne à cette date.")
    end

    return unless event_suivant&.fin_panne?

    errors.add(:état, 'Impossible : une fin de panne est déjà prévue pour plus tard.')
  end

  def nettoyer_reservations_pendant_panne
    # On retrouve la panne qui a déclenché cet incident
    panne_initiale = tool.mouvements
                         .where('date <= ?', date)
                         .where(état: :panne)
                         .order(date: :desc)
                         .first

    return unless panne_initiale

    # On supprime tous les mouvements de réservation situés entre le début et la fin de la panne
    tool.mouvements
         .where(état: "réservé")
         .where(date: panne_initiale.date..date)
         .destroy_all
  end

  def avertir_reservations_futures
    # On cherche toutes les "sorties" (débuts de réservation) prévues APRÈS cette panne
    # On inclut les utilisateurs pour éviter les requêtes N+1
    reservations_futures = tool.mouvements
                               .includes(:user)
                               .where('date > ?', date)
                               .where(état: :réservé)
                               .where.not(user_id: user_id)

    # Pour chaque réservation future, on envoie l'email
    reservations_futures.each do |reservation|
      next unless reservation.user.present?

      # On utilise deliver_later pour que l'envoi de l'email se fasse en arrière-plan
      # sans ralentir le chargement de la page pour la personne qui déclare la panne.
      NotifPanneJob.perform_later(id, reservation.id)
    end
  end

  # Renvoie les mouvements panne/fin_panne encadrant ce mouvement :
  # le voisin de gauche (le passé, <= date) et le voisin de droite (le futur, > date).
  def evenements_panne_voisins
    mouvements_panne_et_fin_panne = tool.mouvements.where.not(id: id).where(état: %i[panne fin_panne])

    event_precedent = mouvements_panne_et_fin_panne.where('date <= ?', date).order(date: :desc).first
    event_suivant = mouvements_panne_et_fin_panne.where('date > ?', date).order(date: :asc).first

    [event_precedent, event_suivant]
  end
end
