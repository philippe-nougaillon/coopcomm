require "test_helper"

class AgentInterventionTest < ActiveSupport::TestCase
  setup do
    @agent_intervention = agent_interventions(:bond_tonte_locaux)
    sign_in users(:hidalgo)
  end
  
end
