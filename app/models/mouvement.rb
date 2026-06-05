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
    fin_panne: 3
  }

  validates :date, presence: true
  validate :coherence_panne, if: :panne?
  validate :coherence_fin_panne, if: :fin_panne?

  after_create :avertir_reservations_futures, if: :panne?
  after_save :nettoyer_reservations_pendant_panne, if: :fin_panne?
  
  def style
    case self.état
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
      tool.mouvements.where(état: :fin_panne).where("date > ?", date).exists?
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

  # TODO : ajouter quelques commentaires ne tuerait personne ;-)
  
  # TODO : vérifier que 'mouvements.date & état' sont indexés car de nombreuses requêtes sont basées dessus... 
  
  def coherence_panne
    # Voisin de gauche (Le passé)
    event_precedent = tool.mouvements.where.not(id: id)
                          .where("date <= ?", date)
                          .where(état: [:panne, :fin_panne])
                          .order(date: :desc).first

    # Voisin de droite (Le futur)
    event_suivant = tool.mouvements.where.not(id: id)
                        .where("date > ?", date)
                        .where(état: [:panne, :fin_panne])
                        .order(date: :asc).first

    if event_precedent&.panne?
      errors.add(:état, "Impossible : l'outil est déjà en panne à ce moment-là.")
    end

    if event_suivant&.panne?
      errors.add(:état, "Impossible : une autre panne est déjà déclarée juste après sans avoir été réparée.")
    end
  end

  # 2. LA VALIDATION POUR LA FIN DE PANNE
  def coherence_fin_panne
    # Voisin de gauche (Le passé)
    event_precedent = tool.mouvements.where.not(id: id)
                          .where("date <= ?", date)
                          .where(état: [:panne, :fin_panne])
                          .order(date: :desc).first

    # Voisin de droite (Le futur)
    event_suivant = tool.mouvements.where.not(id: id)
                        .where("date > ?", date)
                        .where(état: [:panne, :fin_panne])
                        .order(date: :asc).first

    if event_precedent.nil? || event_precedent.fin_panne?
      errors.add(:état, "Impossible : l'outil n'était pas déclaré en panne à cette date.")
    end

    if event_suivant&.fin_panne?
      errors.add(:état, "Impossible : une fin de panne est déjà prévue pour plus tard.")
    end
  end

  def nettoyer_reservations_pendant_panne
    # On retrouve la panne qui a déclenché cet incident
    panne_initiale = tool.mouvements
                         .where("date <= ?", date)
                         .where(état: :panne)
                         .order(date: :desc)
                         .first

    return unless panne_initiale

    # On trouve tous les mouvements de réservation situés entre le début et la fin de la panne
    mouvements_ecrases = tool.mouvements
                             .where(état: [:sortie, :entrée])
                             .where(date: panne_initiale.date..self.date)

    # Pour chaque mouvement trouvé, on supprime la réservation complète (la paire sortie/entrée)
    # On utilise created_at pour retrouver la paire exacte (comme vu précédemment)
    mouvements_ecrases.each do |mvt|
      tool.mouvements.where(user_id: mvt.user_id, created_at: mvt.created_at).destroy_all
    end
  end

  def avertir_reservations_futures
    # On cherche toutes les "sorties" (débuts de réservation) prévues APRÈS cette panne
    # On inclut les utilisateurs pour éviter les requêtes N+1
    reservations_futures = tool.mouvements
                               .includes(:user)
                               .where("date > ?", self.date)
                               .where(état: :sortie)
                               .where.not(user_id: self.user_id)

    # Pour chaque réservation future, on envoie l'email
    reservations_futures.each do |reservation|
      if reservation.user.present?
        # On utilise deliver_later pour que l'envoi de l'email se fasse en arrière-plan
        # sans ralentir le chargement de la page pour la personne qui déclare la panne.
        NotifPanneJob.perform_later(self.id, reservation.id, )
      end
    end
  end
end
