# frozen_string_literal: true

require 'test_helper'

class AbsenceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @agent = users(:bond)
  end

  # Sentinelle : ajouter un motif à l'enum doit suffire. Un libellé écrit à la
  # main finit toujours par diverger (l'historique d'audit annonçait « Maladie »
  # pour un congé parental).
  test 'MOTIF_LABELS : motifs de l\'enum → un libellé pour chacun, sans table à tenir à jour' do
    assert_equal Absence.motifs.keys.sort, Absence::MOTIF_LABELS.keys.sort
    assert_equal 'Congé sans solde', Absence::MOTIF_LABELS['congé_sans_solde']
  end

  test 'no_overlapping_absences : deux demi-journées différentes le même jour → acceptées' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                    motif: :formation, matin: true, après_midi: false)

    après_midi = Absence.new(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                             motif: :formation, matin: false, après_midi: true)

    assert après_midi.valid?, après_midi.errors.full_messages.to_sentence
  end

  test 'no_overlapping_absences : deux absences le même matin → refusée, le message dit « Matin uniquement »' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                    motif: :formation, matin: true, après_midi: false)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                          motif: :formation, matin: true, après_midi: false)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, 'chevauche une autre absence'
    assert_includes doublon.errors.full_messages.to_sentence, '(Matin uniquement)'
  end

  test 'no_overlapping_absences : deux absences le même après-midi → le message dit « Après-midi uniquement »' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                    motif: :formation, matin: false, après_midi: true)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                          motif: :formation, matin: false, après_midi: true)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, '(Après-midi uniquement)'
  end

  test 'no_overlapping_absences : journée entière sur une demi-journée déjà posée → refusée' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9),
                    motif: :formation, matin: true, après_midi: false)

    journée = Absence.new(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9), motif: :formation)

    assert_not journée.valid?
    assert_includes journée.errors.full_messages.to_sentence, 'chevauche une autre absence'
  end

  test 'no_overlapping_absences : mise à jour de l\'absence elle-même → non comptée comme doublon' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 5, 10), au: Date.new(2030, 5, 10),
                              motif: :formation)

    absence.observation = 'Motif précisé'

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'no_overlapping_absences : même jour chez un autre agent → accepté' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11), motif: :formation)

    autre_agent = Absence.new(user: users(:john_wick), du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11),
                              motif: :formation)

    assert autre_agent.valid?, autre_agent.errors.full_messages.to_sentence
  end

  test 'no_overlapping_interventions : absence du matin, intervention l\'après-midi → acceptée' do
    jour = Date.new(2030, 6, 3)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: true, après_midi: false)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'no_overlapping_interventions : absence de l\'après-midi, intervention l\'après-midi → refusée' do
    jour = Date.new(2030, 6, 4)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: false, après_midi: true)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.to_sentence, 'déjà en intervention'
  end

  test 'no_overlapping_interventions : absence de l\'après-midi, intervention le matin → acceptée' do
    jour = Date.new(2030, 6, 5)
    cree_intervention_prevue(jour + 8.hours, jour + 10.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: false, après_midi: true)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  # ÉPINGLAGE B32 : aucune validation de présence sur du/au, donc une absence
  # sans date est enregistrable — et `nb_jours` plante ensuite. À inverser à la
  # correction.
  test 'validations : absence sans date → enregistrable, et nb_jours plante ensuite' do
    absence = Absence.new(user: @agent, motif: :formation)

    assert absence.valid?
    assert_raises(NoMethodError) { absence.nb_jours }
  end

  test 'send_manager_notification : absence créée → notification aux managers avec l\'absence en argument' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 3, 4), au: Date.new(2030, 3, 5), motif: :formation)

    assert_enqueued_with(job: NotifManagersNewAbsenceJob, args: [absence])
  end

  test 'send_manager_notification : absence refusée (fin avant début) → aucune notification' do
    assert_no_enqueued_jobs only: NotifManagersNewAbsenceJob do
      absence = Absence.new(user: @agent, du: Date.new(2030, 3, 6), au: Date.new(2030, 3, 4), motif: :formation)

      assert_not absence.save
    end
  end

  test 'notifier_personne_concernée : création → notification « créée », sans valeurs antérieures' do
    absence = nil

    assert_enqueued_with(job: NotifAgentAbsenceJob) do
      absence = Absence.create!(user: @agent, du: Date.new(2030, 4, 2), au: Date.new(2030, 4, 2), motif: :formation)
    end

    action, resume, resume_avant, email, = enqueued_jobs.find { |j| j['job_class'] == 'NotifAgentAbsenceJob' }['arguments']

    assert_equal 'créée', action
    assert_equal 'Journée entière', resume['période']
    assert_nil resume_avant
    assert_equal @agent.email, email
    assert absence.persisted?
  end

  test 'notifier_personne_concernée : modification → notification « modifiée » avec l\'avant et l\'après' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 4, 3), au: Date.new(2030, 4, 3), motif: :formation)
    clear_enqueued_jobs

    absence.update!(matin: true, motif: :congés_payés)

    action, resume, resume_avant, = enqueued_jobs.find { |j| j['job_class'] == 'NotifAgentAbsenceJob' }['arguments']

    assert_equal 'modifiée', action
    assert_equal 'Matin', resume['période']
    assert_equal 'Congés payés', resume['motif']
    assert_equal 'Journée entière', resume_avant['période']
    assert_equal 'Formation', resume_avant['motif']
  end

  test 'notifier_personne_concernée : suppression → notification « supprimée »' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 4, 4), au: Date.new(2030, 4, 4), motif: :formation)
    clear_enqueued_jobs

    absence.destroy

    action, = enqueued_jobs.find { |j| j['job_class'] == 'NotifAgentAbsenceJob' }['arguments']

    assert_equal 'supprimée', action
  end

  test 'notifier_personne_concernée : auteur et personne concernée confondus → aucune notification' do
    assert_no_enqueued_jobs only: NotifAgentAbsenceJob do
      Audited.audit_class.as_user(@agent) do
        Absence.create!(user: @agent, du: Date.new(2030, 4, 5), au: Date.new(2030, 4, 5), motif: :formation)
      end
    end
  end

  test 'en_cours? : absence qui couvre aujourd\'hui → vrai' do
    absence = Absence.new(user: @agent, du: Date.current, au: Date.current, motif: :formation)

    assert absence.en_cours?
  end

  test 'en_cours? : absence hors d\'aujourd\'hui → faux' do
    assert_not absence_2030.en_cours?
  end

  test 'nb_jours : absence de trois jours → les deux bornes comptées' do
    absence = absence_2030
    absence.au = absence.du + 2.days

    assert_equal 3, absence.nb_jours
  end

  # Les deux booléens à false signifient « journée entière », pas « rien ».

  test 'takes_morning? / takes_afternoon? : matin seul → le matin, pas l\'après-midi' do
    absence = absence_2030(matin: true, après_midi: false)

    assert absence.takes_morning?
    assert_not absence.takes_afternoon?
  end

  test 'takes_morning? / takes_afternoon? : après-midi seul → l\'après-midi, pas le matin' do
    absence = absence_2030(matin: false, après_midi: true)

    assert_not absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'takes_morning? / takes_afternoon? : aucune demi-journée cochée → journée entière' do
    absence = absence_2030(matin: false, après_midi: false)

    assert absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'takes_morning? / takes_afternoon? : les deux demi-journées cochées → journée entière' do
    absence = absence_2030(matin: true, après_midi: true)

    assert absence.takes_morning?
    assert absence.takes_afternoon?
  end

  private

  def absence_2030(attributs = {})
    Absence.new({ user: @agent, du: Date.new(2030, 4, 8), au: Date.new(2030, 4, 8),
                  motif: :formation }.merge(attributs))
  end

  def cree_intervention_prevue(debut, fin)
    Intervention.create!(
      description: 'Intervention planifiée',
      service: services(:technique),
      adherent: users(:weil),
      workflow_state: 'nouveau',
      début_prévue: debut,
      fin_prévue: fin,
      agents: [@agent]
    )
  end
end
