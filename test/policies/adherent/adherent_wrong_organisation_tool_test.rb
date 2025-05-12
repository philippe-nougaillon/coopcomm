require "test_helper"

class AdherentWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_marseille = users(:adherent_marseille)
    
    tool_paris = tools(:outil_paris)

    @wrongPolicy = ToolPolicy.new(adherent_marseille, tool_paris)
  end

  test "should refute show with wrong organisation" do
    refute @wrongPolicy.show?
  end
end