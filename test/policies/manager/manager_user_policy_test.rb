require "test_helper"

class ManagerUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)
    
    user_paris = users(:user_paris)

    @policy = UserPolicy.new(manager_paris, user_paris)
  end

  # Index
  test "accès manager user index autorisé" do
    assert @policy.index?
  end

  # Show
  test "accès manager user show autorisé" do
    assert @policy.show?
  end

  # New
  test "accès manager user new autorisé" do
    assert @policy.new?
  end

  # Create
  test "accès manager user create autorisé" do
    assert @policy.create?
  end

  # Edit
  test "accès manager user edit autorisé" do
    assert @policy.edit?
  end

  # Update
  test "accès manager user update autorisé" do
    assert @policy.update?
  end

  # Destroy
  test "accès manager user destroy autorisé" do
    assert @policy.destroy?
  end

  # agent calendrier
  test "accès manager user agent calendrier autorisé" do
    assert @policy.agent_calendrier?
  end
end
