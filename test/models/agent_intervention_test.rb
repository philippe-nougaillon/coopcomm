require "test_helper"

class AgentInterventionTest < ActiveSupport::TestCase
  setup do
    @agent_intervention = agent_interventions(:bond_tonte_locaux)
    sign_in users(:hidalgo)
  end

  test "overlap agents" do
    # Créer deux interventions avec un agent qui se chevauchent
    puts create_intervention_chevauche(@agent_intervention.intervention)

    
    assert true
  end

  def create_intervention_chevauche(intervention_a_chevaucher)
    intervention_chevauchement = Intervention.new
    intervention_chevauchement.description = "Intervention en chevauchement"
    intervention_chevauchement.début_prévue = intervention_a_chevaucher.début_prévue
    intervention_chevauchement.organisation_id = intervention_a_chevaucher.organisation_id
    intervention_chevauchement.save

    ai = AgentIntervention.new
    ai.agent_id = @agent_intervention.agent.id
    ai.intervention_id = intervention_chevauchement.id
    puts ai.save
    return intervention_chevauchement.début_prévue, intervention_a_chevaucher.début_prévue
  end
end
