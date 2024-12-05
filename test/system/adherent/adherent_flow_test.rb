require "application_system_test_case"

class AdherentFlowTest < ApplicationSystemTestCase

  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end
  
  test "Visiter la liste des interventions" do
    assert_selector "h1", text: "Interventions"
  end

  test "Voir que ses interventions" do
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_adhérent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  # test "voir que ses activités" do
    # (audit)
  # end

end