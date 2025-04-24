require "test_helper"

class ManagerToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)
    
    tool_paris = tools(:outil_paris)

    @policy = ToolPolicy.new(manager_paris, tool_paris)
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
  test "should get new" do
    assert @policy.new?
  end

  # Create
  test "should get create" do
    assert @policy.create?
  end

  # Edit
  test "should get edit" do
    assert @policy.edit?
  end

  # Update
  test "should get update" do
    assert @policy.update?
  end

  # Destroy
  test "should get destroy" do
    assert @policy.destroy?
  end
end
