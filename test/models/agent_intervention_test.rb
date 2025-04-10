require "test_helper"

class AgentInterventionTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
  end

  test "Intervention créée si l'agent est disponible" do
    intervention = defaultIntervention

    assert intervention.valid?
  end

  test "Intervention non créée si l'agent est occupé à la même heure" do
    intervention = defaultIntervention

    nouvelle_intervention = tooMuchIntervention(intervention.début_prévue, intervention.fin_prévue)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent commence avant et fini pendant" do
    intervention = defaultIntervention

    début_prévue_décalé = intervention.début_prévue - 1.hour
    fin_prévue_décalé = intervention.fin_prévue + 0.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent commence pendant et fini après" do
    intervention = defaultIntervention

    début_prévue_décalé = intervention.début_prévue + 0.hour
    fin_prévue_décalé = intervention.fin_prévue + 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent commence pendant et fini pendant" do
    intervention = defaultIntervention

    début_prévue_décalé = intervention.début_prévue + 1.hour
    fin_prévue_décalé = intervention.fin_prévue - 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent commence avant et fini après" do
    intervention = defaultIntervention

    début_prévue_décalé = intervention.début_prévue - 1.hour
    fin_prévue_décalé = intervention.fin_prévue + 1.hour

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent fini au début" do
    intervention = defaultIntervention

    fin_prévue_décalé = intervention.début_prévue

    nouvelle_intervention = tooMuchIntervention(nil, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
  end

  test "Intervention non créée si l'agent commence à la fin" do
    intervention = defaultIntervention

    début_prévue_décalé = intervention.fin_prévue

    nouvelle_intervention = tooMuchIntervention(début_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], "Conflit(s) détecté(s) sur un agent"
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

  def defaultIntervention
    Intervention.create!(
      début_prévue: "2025-04-08 09:00",
      fin_prévue: "2025-04-08 12:00",
      description: "Entretien des locaux",
      organisation: organisations(:mairie_paris),
      agents: [@agent]
    )
  end

end
