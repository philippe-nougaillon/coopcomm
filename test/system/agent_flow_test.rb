require "application_system_test_case"

class AgentFlowTest < ApplicationSystemTestCase

  setup do
    login(@agent)
  end
  
  test "visiting the index" do
    visit interventions_url
    assert_selector "h1", text: "Interventions"
  end

  test "voir que ses interventions" do
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:autre_intervention)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

end