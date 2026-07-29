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
