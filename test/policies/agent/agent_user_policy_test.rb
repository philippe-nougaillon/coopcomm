require "test_helper"

class AgentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)
    
    user_paris = users(:user_paris)

    @policy = UserPolicy.new(agent_paris, user_paris)
  end

  # Index
  test "accès agent user index interdit" do
    refute @policy.index?
  end

  # Show
  test "accès agent user show interdit" do
    refute @policy.show?
  end

  # New
  test "accès agent user new interdit" do
    refute @policy.new?
  end

  # Create
  test "accès agent user create interdit" do
    refute @policy.create?
  end

  # Edit
  test "accès agent user edit interdit" do
    refute @policy.edit?
  end

  # Update
  test "accès agent user update interdit" do
    refute @policy.update?
  end

  # Destroy
  test "accès agent user destroy interdit" do
    refute @policy.destroy?
  end

  # Agent calendrier
  test "accès agent user agent calendrier interdit" do
    refute @policy.agent_calendrier?
  end
end
