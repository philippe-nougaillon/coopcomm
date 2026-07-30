# frozen_string_literal: true

require 'test_helper'

class AbsenceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @agent = users(:bond)
  end

  test 'Une intervention ne se créée pas si un agent est absent' do
    absence = createAbsence

    intervention = createOverlapsIntervention(absence.du, absence.au)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent à la même heure" do
    absence = createAbsence

    nouvelle_intervention = createOverlapsIntervention(absence.du, absence.au)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent avant et pendant" do
    absence = createAbsence

    début_prévue_décalé = absence.du - 1.hour
    fin_prévue_décalé = absence.au + 0.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent pendant et après" do
    absence = createAbsence

    début_prévue_décalé = absence.du + 0.hour
    fin_prévue_décalé = absence.au + 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent pendant et pendant" do
    absence = createAbsence

    début_prévue_décalé = absence.du + 1.hour
    fin_prévue_décalé = absence.au - 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent avant et après" do
    absence = createAbsence

    début_prévue_décalé = absence.du - 1.hour
    fin_prévue_décalé = absence.au + 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent au début" do
    absence = createAbsence

    fin_prévue_décalé = absence.du

    nouvelle_intervention = createOverlapsIntervention(nil, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  test "Intervention non créée si l'agent est absent à la fin" do
    absence = createAbsence

    début_prévue_décalé = absence.au

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Agent(s) indisponible(s)'
  end

  # --- Notification des managers à la création (after_create_commit) ---
  # Dates en 2030 : loin des fixtures d'absence (2024-11) et des interventions de bond,
  # pour ne déclencher aucune validation de chevauchement.

  test "la création d'une absence enqueue la notification aux managers avec l'absence en argument" do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 3, 4), au: Date.new(2030, 3, 5), motif: :formation)

    assert_enqueued_with(job: NotifManagersNewAbsenceJob, args: [absence])
  end

  test "une absence invalide (fin avant début) n'enqueue aucune notification" do
    assert_no_enqueued_jobs only: NotifManagersNewAbsenceJob do
      absence = Absence.new(user: @agent, du: Date.new(2030, 3, 6), au: Date.new(2030, 3, 4), motif: :formation)
      assert_not absence.save
    end
  end

  # --- Demi-journées : takes_morning? / takes_afternoon? ---
  # Les deux booléens à false signifient « journée entière », pas « rien ».

  test 'une absence du matin prend le matin et pas l\'après-midi' do
    absence = absence_2030(matin: true, après_midi: false)

    assert absence.takes_morning?
    assert_not absence.takes_afternoon?
  end

  test 'une absence de l\'après-midi prend l\'après-midi et pas le matin' do
    absence = absence_2030(matin: false, après_midi: true)

    assert_not absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'une absence sans demi-journée cochée couvre la journée entière' do
    absence = absence_2030(matin: false, après_midi: false)

    assert absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'une absence avec les deux demi-journées cochées couvre la journée entière' do
    absence = absence_2030(matin: true, après_midi: true)

    assert absence.takes_morning?
    assert absence.takes_afternoon?
  end

  test 'nb_jours compte les deux bornes incluses' do
    absence = absence_2030
    absence.au = absence.du + 2.days

    assert_equal 3, absence.nb_jours
  end

  test 'en_cours? est vrai pour une absence qui couvre aujourd\'hui' do
    absence = Absence.new(user: @agent, du: Date.current, au: Date.current, motif: :formation)

    assert absence.en_cours?
  end

  test 'en_cours? est faux pour une absence passée' do
    assert_not absence_2030.en_cours?
  end

  # --- Chevauchement entre absences (no_overlapping_absences) ---

  test 'deux absences le même jour sur des demi-journées différentes ne se chevauchent pas' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                    motif: :formation, matin: true, après_midi: false)

    apres_midi = Absence.new(user: @agent, du: Date.new(2030, 5, 6), au: Date.new(2030, 5, 6),
                             motif: :formation, matin: false, après_midi: true)

    assert apres_midi.valid?, apres_midi.errors.full_messages.to_sentence
  end

  test 'deux absences le même matin se chevauchent et le message précise « Matin uniquement »' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                    motif: :formation, matin: true, après_midi: false)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 7), au: Date.new(2030, 5, 7),
                          motif: :formation, matin: true, après_midi: false)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, 'chevauche une autre absence'
    assert_includes doublon.errors.full_messages.to_sentence, '(Matin uniquement)'
  end

  test 'le message de chevauchement précise « Après-midi uniquement » quand c\'est le cas' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                    motif: :formation, matin: false, après_midi: true)

    doublon = Absence.new(user: @agent, du: Date.new(2030, 5, 8), au: Date.new(2030, 5, 8),
                          motif: :formation, matin: false, après_midi: true)

    assert_not doublon.valid?
    assert_includes doublon.errors.full_messages.to_sentence, '(Après-midi uniquement)'
  end

  test 'une absence journée entière chevauche une demi-journée déjà posée' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9),
                    motif: :formation, matin: true, après_midi: false)

    journee = Absence.new(user: @agent, du: Date.new(2030, 5, 9), au: Date.new(2030, 5, 9),
                          motif: :formation)

    assert_not journee.valid?
    assert_includes journee.errors.full_messages.to_sentence, 'chevauche une autre absence'
  end

  test 'la modification d\'une absence ne la considère pas comme son propre doublon' do
    absence = Absence.create!(user: @agent, du: Date.new(2030, 5, 10), au: Date.new(2030, 5, 10),
                              motif: :formation)

    absence.observation = 'Motif précisé'

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'une absence chez un autre agent ne provoque aucun chevauchement' do
    Absence.create!(user: @agent, du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11), motif: :formation)

    autre_agent = Absence.new(user: users(:john_wick), du: Date.new(2030, 5, 11), au: Date.new(2030, 5, 11),
                              motif: :formation)

    assert autre_agent.valid?, autre_agent.errors.full_messages.to_sentence
  end

  # --- Chevauchement avec les interventions (no_overlapping_interventions) ---

  test 'une absence du matin seul n\'entre pas en conflit avec une intervention de l\'après-midi' do
    jour = Date.new(2030, 6, 3)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation,
                          matin: true, après_midi: false)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'une absence de l\'après-midi seul entre en conflit avec une intervention de l\'après-midi' do
    jour = Date.new(2030, 6, 4)
    cree_intervention_prevue(jour + 14.hours, jour + 16.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation,
                          matin: false, après_midi: true)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.to_sentence, 'déjà en intervention'
  end

  test 'une absence de l\'après-midi seul n\'entre pas en conflit avec une intervention du matin' do
    jour = Date.new(2030, 6, 5)
    cree_intervention_prevue(jour + 8.hours, jour + 10.hours)

    absence = Absence.new(user: @agent, du: jour, au: jour, motif: :formation,
                          matin: false, après_midi: true)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  # ÉPINGLAGE B32 : aucune validation de présence sur du/au, donc une absence
  # sans date est enregistrable — et `nb_jours` plante ensuite. À inverser à la
  # correction.
  test 'une absence sans date reste valide et fait planter nb_jours' do
    absence = Absence.new(user: @agent, motif: :formation)

    assert absence.valid?
    assert_raises(NoMethodError) { absence.nb_jours }
  end

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

  def createOverlapsIntervention(debut = nil, fin = nil)
    Intervention.new(
      début_prévue: debut,
      fin_prévue: fin,
      description: "L'intervention de trop",
      organisation: organisations(:mairie_paris),
      agents: [@agent]
    )
  end

  def createAbsence
    Absence.create!(
      du: '2025-04-08 9:00',
      au: '2025-04-08 12:00',
      motif: 0,
      observation: 'Vacances',
      user: @agent
    )
  end
end
