require "test_helper"

class AbsenceTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
  end

  test "Une intervention ne se créée pas si un agent est absent" do
    absence = getAbsence

    intervention = tooMuchIntervention(absence.du, absence.au)

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent à la même heure" do
    absence = getAbsence

    nouvelle_intervention = tooMuchIntervention(absence.du, absence.au)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent avant et pendant" do
    absence = getAbsence

    début_prévue_décalé = absence.du - 1.hour
    fin_prévue_décalé = absence.au + 0.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent pendant et après" do
    absence = getAbsence

    début_prévue_décalé = absence.du + 0.hour
    fin_prévue_décalé = absence.au + 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent pendant et pendant" do
    absence = getAbsence

    début_prévue_décalé = absence.du + 1.hour
    fin_prévue_décalé = absence.au - 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent avant et après" do
    absence = getAbsence

    début_prévue_décalé = absence.du - 1.hour
    fin_prévue_décalé = absence.au + 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent au début" do
    absence = getAbsence

    fin_prévue_décalé = absence.du

    nouvelle_intervention = tooMuchIntervention(nil, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  test "Intervention non créée si l'agent est absent à la fin" do
    absence = getAbsence

    début_prévue_décalé = absence.au

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end

  def tooMuchIntervention(debut = nil, fin = nil)
    Intervention.new(
      début_prévue: debut,
      fin_prévue: fin,
      description: "L'intervention de trop",
      organisation: organisations(:mairie_paris),
      agents: [@agent]
    )
  end

  def getAbsence
    Absence.create!(
      du: "2025-04-08 9:00",
      au: "2025-04-08 12:00",
      motif: "Arrêt maladie",
      user: @agent
    )
  end
end
