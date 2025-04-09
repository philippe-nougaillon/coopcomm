require "test_helper"

class AbsenceTest < ActiveSupport::TestCase
  test "Une intervention ne se créée pas si un agent est absent" do
    Absence.create!(
      du: "2025-04-08 10:00",
      au: "2025-04-08 12:00",
      motif: "Arrêt maladie",
      user: @agent
    )

    intervention = Intervention.new(
      début_prévue: "2025-04-08 10:00",
      fin_prévue: "2025-04-08 12:00",
      description: "Comptabilité des outils",
      organisation: organisations(:mairie_paris),
      agents: [@agent]
    )

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages[0], "Agent(s) indisponible(s)"
  end
end
