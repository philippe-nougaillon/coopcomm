# frozen_string_literal: true

class Absence < ApplicationRecord
  audited associated_with: :user

  belongs_to :user

  scope :ordered, -> { order(du: :desc) }

  triable_par 'absences.du' => :brut, 'absences.motif' => :brut, 'absences.observation' => :texte

  enum :motif, {
    congés_payés: 0,
    congé_parental: 1,
    formation: 2,
    congé_sans_solde: 3
  }

  MOTIF_LABELS = motifs.keys.index_with(&:humanize).freeze

  validate :dates_must_make_sense
  validate :no_overlapping_absences
  validate :no_overlapping_interventions

  # after_create_commit au lieu de after_create pour être sûr que l'audit de création soit créé et utilisable
  after_create_commit :send_manager_notification

  after_create_commit  -> { notifier_personne_concernée('créée') }
  after_update_commit  -> { notifier_personne_concernée('modifiée') }
  after_destroy_commit -> { notifier_personne_concernée('supprimée') }

  def en_cours?
    (du..au).include?(Date.today)
  end

  def nb_jours
    (au - du).to_i + 1
  end

  def send_manager_notification
    NotifManagersNewAbsenceJob.perform_later(self)
  end

  def résumé(attributs = {})
    source = attributes.merge(attributs)

    {
      'du' => source['du'],
      'au' => source['au'],
      'période' => période_libellé(source['matin'], source['après_midi']),
      'motif' => MOTIF_LABELS[source['motif']] || source['motif'],
      'observation' => source['observation']
    }
  end

  def résumé_avant
    résumé(saved_changes.transform_values(&:first))
  end

  def takes_morning?
    matin || (!matin && !après_midi) || (matin && après_midi)
  end

  def takes_afternoon?
    après_midi || (!matin && !après_midi) || (matin && après_midi)
  end

  def début_datetime
    après_midi && !matin ? du.middle_of_day : du.beginning_of_day
  end

  def fin_datetime
    matin && !après_midi ? au.middle_of_day : au.end_of_day
  end

  def demi_journée?
    matin ^ après_midi
  end

  # Affine un chevauchement déjà établi au jour près ; 12:00 appartient à l'après-midi.
  def couvre?(debut, fin)
    return true unless demi_journée?

    debut = en_datetime(debut) || en_datetime(fin)
    fin   = en_datetime(fin) || debut
    return false if debut.blank? || du.blank? || au.blank?
    return debut >= début_datetime && debut < fin_datetime if debut == fin

    debut < fin_datetime && fin > début_datetime
  end

  private

  def période_libellé(matin, après_midi)
    return 'Matin' if matin && !après_midi
    return 'Après-midi' if après_midi && !matin

    'Journée entière'
  end

  # L'auteur se lit dans l'audit trail ; la suppression y écrit aussi sa ligne.
  def auteur_id
    audits.reorder(:created_at).last&.user_id
  end

  def notifier_personne_concernée(action)
    return if user.blank? || user.email.blank?

    auteur = auteur_id
    return if auteur == user_id

    NotifAgentAbsenceJob.perform_later(action, résumé, (résumé_avant if action == 'modifiée'),
                                       user.email, user.organisation&.id, auteur)
  end

  def en_datetime(valeur)
    return nil if valeur.blank?

    valeur.to_time
  end

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

    interventions_en_conflit = user.interventions.where(
      "#{Intervention::EFFECTIVE_DEBUT_SQL} < ? AND #{Intervention::EFFECTIVE_FIN_SQL} > ?",
      fin_datetime,
      début_datetime
    )

    return if interventions_en_conflit.empty?

    messages = interventions_en_conflit.map do |intervention|
      "« #{intervention.description} » du #{intervention.effective_début&.strftime('%d/%m/%Y %H:%M')} " \
        "au #{intervention.effective_fin&.strftime('%d/%m/%Y %H:%M')}"
    end

    errors.add(:base,
               "Impossible d'enregistrer l'absence : la personne est déjà en intervention sur ce créneau horaire — #{messages.to_sentence}.")
  end

  def genuinely_overlaps?(other)
    my_morning   = takes_morning?
    my_afternoon = takes_afternoon?

    other_morning   = other.takes_morning?
    other_afternoon = other.takes_afternoon?

    (my_morning && other_morning) || (my_afternoon && other_afternoon)
  end
end
