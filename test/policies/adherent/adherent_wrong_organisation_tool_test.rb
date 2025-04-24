require "test_helper"

class AdherentWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_marseille = users(:adherent_marseille)
    
    intervention_paris = interventions(:intervention_paris)

    @wrongPolicy = ToolPolicy.new(adherent_marseille, intervention_paris)
  end

  test "should refute show with wrong organisation" do
    refute @wrongPolicy.show?
  end
end