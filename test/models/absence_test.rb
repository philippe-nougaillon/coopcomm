# frozen_string_literal: true

require 'test_helper'

class AbsenceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @agent = users(:bond)
  end

  test 'chaque motif de l\'enum a son libellé, sans table à tenir à jour' do
    assert_equal Absence.motifs.keys.sort, Absence::MOTIF_LABELS.keys.sort
    assert_equal 'Congé sans solde', Absence::MOTIF_LABELS['congé_sans_solde']
  end

  test 'deux demi-journées différentes le même jour sont acceptées' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                    motif: :formation, matin: true, après_midi: false)

    après_midi = Absence.new(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                             motif: :formation, matin: false, après_midi: true)

    assert après_midi.valid?, après_midi.errors.full_messages.to_sentence
  end

  test 'deux absences le même matin sont refusées, et le message précise « Matin uniquement »' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                    motif: :formation, matin: true, après_midi: false)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                          motif: :formation, matin: true, après_midi: false)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, 'chevauche une autre absence'
    assert_includes doublon.errors.full_messages.to_sentence, '(Matin uniquement)'
  end

  test 'deux absences le même après-midi sont refusées, et le message précise « Après-midi uniquement »' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                    motif: :formation, matin: false, après_midi: true)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                          motif: :formation, matin: false, après_midi: true)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, '(Après-midi uniquement)'
  end

  test 'une absence d\'une journée entière est refusée si une demi-journée est déjà posée' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9),
                    motif: :formation, matin: true, après_midi: false)

    journée = Absence.new(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9), motif: :formation)

    assert_not journée.valid?
    assert_includes journée.errors.full_messages.to_sentence, 'chevauche une autre absence'
  end

  test 'une absence modifiée n\'est pas comptée comme son propre doublon' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 5, 10), au: Date.new(2030, 5, 10),
                              motif: :formation)

    absence.observation = 'Motif précisé'

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'deux agents peuvent être absents le même jour' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11), motif: :formation)

    autre_agent = Absence.new(user: users(:john_wick), du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11),
                              motif: :formation)

    assert autre_agent.valid?, autre_agent.errors.full_messages.to_sentence
  end

  test 'une absence du matin est acceptée lorsque l\'intervention a lieu l\'après-midi' do
    jour = Date.new(2030, 6, 3)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: true, après_midi: false)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'une absence de l\'après-midi est refusée lorsque l\'intervention a lieu l\'après-midi' do
    jour = Date.new(2030, 6, 4)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: false, après_midi: true)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.to_sentence, 'déjà en intervention'
  end

  test 'une absence de l\'après-midi est acceptée lorsque l\'intervention a lieu le matin' do
    jour = Date.new(2030, 6, 5)
    cree_intervention_prevue(jour + 8.hours, jour + 10.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation, matin: false, après_midi: true)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'les managers sont notifiés à la création d\'une absence' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 3, 4), au: Date.new(2030, 3, 5), motif: :formation)

    assert_enqueued_with(job: NotifManagersNewAbsenceJob, args: [absence])
  end

  test 'aucun manager n\'est notifié lorsque l\'absence est refusée' do
    assert_no_enqueued_jobs only: NotifManagersNewAbsenceJob do
      absence = Absence.new(user: @agent, du: Date.new(2030, 3, 6), au: Date.new(2030, 3, 4), motif: :formation)

      assert_not absence.save
    end
  end

  test 'la personne concernée est notifiée de la création, sans valeurs antérieures' do
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

  test 'la personne concernée est notifiée de la modification, avec l\'avant et l\'après' do
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

  test 'la personne concernée est notifiée de la suppression' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 4, 4), au: Date.new(2030, 4, 4), motif: :formation)
    clear_enqueued_jobs

    absence.destroy

    action, = enqueued_jobs.find { |j| j['job_class'] == 'NotifAgentAbsenceJob' }['arguments']

    assert_equal 'supprimée', action
  end

  test 'la personne concernée n\'est pas notifiée lorsqu\'elle est l\'auteur de l\'absence' do
    assert_no_enqueued_jobs only: NotifAgentAbsenceJob do
      Audited.audit_class.as_user(@agent) do
        Absence.create!(user: @agent, du: Date.new(2030, 4, 5), au: Date.new(2030, 4, 5), motif: :formation)
      end
    end
  end

  test 'une absence qui couvre aujourd\'hui est en cours' do
    absence = Absence.new(user: @agent, du: Date.current, au: Date.current, motif: :formation)

    assert absence.en_cours?
  end

  test 'une absence à venir n\'est pas en cours' do
    assert_not absence_2030.en_cours?
  end

  test 'le nombre de jours d\'une absence compte ses deux bornes' do
    absence = absence_2030
    absence.au = absence.du + 2.days

    assert_equal 3, absence.nb_jours
  end

  test 'une absence du matin ne prend pas l\'après-midi' do
    absence = absence_2030(matin: true, après_midi: false)

    assert absence.takes_morning?
    assert_not absence.takes_afternoon?
  end

  test 'une absence de l\'après-midi ne prend pas le matin' do
    absence = absence_2030(matin: false, après_midi: true)

    assert_not absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'une absence sans demi-journée cochée vaut une journée entière' do
    absence = absence_2030(matin: false, après_midi: false)

    assert absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'une absence dont les deux demi-journées sont cochées vaut une journée entière' do
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
