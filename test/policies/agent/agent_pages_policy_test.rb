require "test_helper"

class AgentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(agent_paris, nil)
  end

  # Assistant
  test "accès interdit pour un agent pour un assistant de pages" do
    refute @policy.assistant?
  end

  # Dashboard
  test "accès interdit pour un agent pour un dashboard de pages" do
    refute @policy.dashboard?
  end
end
