require "test_helper"

class ToolInterventionTest < ActiveSupport::TestCase

  test "Une intervention ne se créée pas si un outil n'est pas disponible" do
    tool = Tool.create!(name: "Tournevis laser", organisation: organisations(:mairie_paris))
    existing = Intervention.create!(
      début_prévue: "2025-04-08 10:00",
      fin_prévue: "2025-04-08 12:00",
      description: "Maintenance X",
      organisation:organisations(:mairie_paris),
      tools: [tool]
    )

    new_intervention = Intervention.new(
      début_prévue: "2025-04-08 12:00", # juste après, donc interdit
      fin_prévue: "2025-04-08 14:00",
      description: "Maintenance Y",
      organisation: organisations(:mairie_paris),
      tools: [tool]
    )

    assert_not new_intervention.valid?
    assert_includes new_intervention.errors.full_messages[0], "Tournevis laser"
  end
end
