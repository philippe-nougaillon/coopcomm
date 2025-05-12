require "test_helper"

class AdherentUserPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)
    
    user_paris = users(:user_paris)

    @policy = UserPolicy.new(adherent_paris, user_paris)
  end

  # Index
  test "accès adhérent user index interdit" do
    refute @policy.index?
  end

  # Show
  test "accès adhérent user show interdit" do
    refute @policy.show?
  end

  # New
  test "accès adhérent user new interdit" do
    refute @policy.new?
  end

  # Create
  test "accès adhérent user create interdit" do
    refute @policy.create?
  end

  # Edit
  test "accès adhérent user edit interdit" do
    refute @policy.edit?
  end

  # Update
  test "accès adhérent user update interdit" do
    refute @policy.update?
  end

  # Destroy
  test "accès adhérent user destroy interdit" do
    refute @policy.destroy?
  end

  # Agent calendrier
  test "accès adhérent user agent calendrier interdit" do
    refute @policy.agent_calendrier?
  end
end
