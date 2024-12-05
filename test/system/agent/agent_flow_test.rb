require "application_system_test_case"

class AgentFlowTest < ApplicationSystemTestCase

  setup do
    @agent = users(:bond)
    login(@agent)
  end
  
  test "Visiter la liste des interventions" do
    assert_selector "h1", text: "Interventions"
  end

  test "Ne voir que ses interventions" do
    agent_intervention = interventions(:tonte_locaux)
    other_intervention = interventions(:intervention_autre_agent)
    assert_text agent_intervention.description
    assert_no_text other_intervention.description
  end

  # test "voir que ses activités" do
    # (audit)
  # end

end