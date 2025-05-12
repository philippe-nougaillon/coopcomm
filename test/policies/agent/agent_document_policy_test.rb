require "test_helper"

class AgentDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)
    
    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(agent_paris, document)
  end

  # Valider
  test "accès agent document valider interdit" do
    refute @policy.valider?
  end

  # Refuser
  test "accès agent document refuser interdit" do
    refute @policy.refuser?
  end
end
