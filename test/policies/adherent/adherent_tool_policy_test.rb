require "test_helper"

class AdherentToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)
    
    tool_paris = tools(:outil_paris)

    @policy = ToolPolicy.new(adherent_paris, tool_paris)
  end

  # Index
  test "should get index" do
    assert @policy.index?
  end

  # Show
  test "should get show" do
    assert @policy.show?
  end

  # New
  test "should refute new with adherent" do
    refute @policy.new?
  end

  # Create
  test "should refute create with adherent" do
    refute @policy.create?
  end

  # Edit
  test "should refute edit with adherent" do
    refute @policy.edit?
  end

  # Update
  test "should refute update with adherent" do
    refute @policy.update?
  end

  # Destroy
  test "should refute destroy with adherent" do
    refute @policy.destroy?
  end
end
