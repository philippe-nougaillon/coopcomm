require "test_helper"

class AgentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)
    
    user_paris = users(:user_paris)

    @policy = UserPolicy.new(agent_paris, user_paris)
    @policy_user_myself = UserPolicy.new(agent_paris, agent_paris)
  end

  # Index
  test "accès agent user index interdit" do
    refute @policy.index?
  end

  # Show
  test "accès agent user show interdit" do
    refute @policy.show?
  end

  test "accès autorisé pour un agent sur sa page show" do
    assert @policy_user_myself.show?
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

  # Inviter
  test "accès interdit pour un agent sur la page inviter d'un user" do
    refute @policy.inviter?
  end

  # Edit password
  test "accès autorisé pour un agent sur sa page edit_password" do
    assert @policy_user_myself.edit_password?
  end

  # Update password
  test "accès autorisé pour un agent sur sa page update_password" do
    assert @policy_user_myself.update_password?
  end

  # Reactivate
  test "accès interdit pour un agent sur la page reactivate d'un user" do
    refute @policy.reactivate?
  end
end
