# frozen_string_literal: true

class Absence < ApplicationRecord
  audited associated_with: :user

  belongs_to :user

  scope :ordered, -> { order(du: :desc) }

  enum :motif, {
    congés_payés: 0,
    congé_parental: 1,
    formation: 2,
    congé_sans_solde: 3
  }

  MOTIF_LABELS = {
    'congés_payés' => 'Congés payés',
    'congé_parental' => 'Congé parental',
    'formation' => 'Formation',
    'congé_sans_solde' => 'Congé sans solde'
  }.freeze

  validate :dates_must_make_sense
  validate :no_overlapping_absences
  validate :no_overlapping_interventions

  # after_create_commit au lieu de after_create pour être sûr que l'audit de création soit créé et utilisable
  after_create_commit :send_manager_notification

  Absence::MOTIF_LABELS

  def en_cours?
    (du..au).include?(Date.today)
  end

  def nb_jours
    (au - du).to_i + 1
  end

  def send_manager_notification
    NotifManagersNewAbsenceJob.perform_later(self)
  end

  def takes_morning?
    matin || (!matin && !après_midi) || (matin && après_midi)
  end

  def takes_afternoon?
    après_midi || (!matin && !après_midi) || (matin && après_midi)
  end

  private

  def dates_must_make_sense
    return unless du && au && (du > au)

    errors.add(:base, ": La fin de l'absence ne peut pas être avant son commencement")
  end

  def no_overlapping_absences
    return if du.blank? || au.blank? || user_id.blank?

    overlapping_absences = Absence.where(user_id: user_id)
                                  .where('du <= ? AND au >= ?', au, du)
                                  .where.not(id: id)

    overlapping_absences.each do |other_absence|
      next unless genuinely_overlaps?(other_absence)

      # On construit un résumé clair de l'absence en conflit
      conflit_info = "du #{other_absence.du.strftime('%d/%m/%Y')} au #{other_absence.au.strftime('%d/%m/%Y')}"

      # On ajoute une précision si c'est une demi-journée spécifique
      if other_absence.matin && !other_absence.après_midi
        conflit_info += ' (Matin uniquement)'
      elsif !other_absence.matin && other_absence.après_midi
        conflit_info += ' (Après-midi uniquement)'
      end

      # On injecte l'information dans l'erreur
      errors.add(:base, "Cette absence chevauche une autre absence déjà enregistrée #{conflit_info}.")
      break
    end
  end

  def no_overlapping_interventions
    return if du.blank? || au.blank? || user.blank?

    absence_start = du.beginning_of_day
    absence_end   = au.end_of_day

    if matin && !après_midi
      absence_end = au.middle_of_day
    elsif après_midi && !matin
      absence_start = du.middle_of_day
    end
    # Si les deux sont à false (ou les deux à true), les bornes par défaut
    # couvrent toute la journée, ce qui correspond à ton besoin.

    interventions_en_conflit = user.interventions.where(
      'début_prévue < ? AND fin_prévue > ?',
      absence_end,
      absence_start
    )

    return unless interventions_en_conflit.exists?

    errors.add(:base, "Impossible de créer l'absence : la personne est déjà en intervention sur ce créneau horaire.")
  end

  def genuinely_overlaps?(other)
    my_morning   = takes_morning?
    my_afternoon = takes_afternoon?

    other_morning   = other.takes_morning?
    other_afternoon = other.takes_afternoon?

    (my_morning && other_morning) || (my_afternoon && other_afternoon)
  end
end
