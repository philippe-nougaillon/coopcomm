# frozen_string_literal: true

require 'test_helper'

class AgentToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    tool_paris = tools(:outil_paris)

    @policy = ToolPolicy.new(agent_paris, tool_paris)
  end

  # Index
  test 'should get index' do
    assert @policy.index?
  end

  # Show
  test 'should get show' do
    assert @policy.show?
  end

  # New
  test 'should refute new with agent' do
    refute @policy.new?
  end

  # Create
  test 'should refute create with agent' do
    refute @policy.create?
  end

  # Edit
  test 'should refute edit with agent' do
    refute @policy.edit?
  end

  # Update
  test 'should refute update with agent' do
    refute @policy.update?
  end

  # Destroy
  test 'should refute destroy with agent' do
    refute @policy.destroy?
  end
end
