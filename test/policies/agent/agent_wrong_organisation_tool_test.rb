# frozen_string_literal: true

require 'test_helper'

class AgentWrongOrganisationToolPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_marseille = users(:agent_marseille)

    tool_paris = tools(:outil_paris)

    @wrongPolicy = ToolPolicy.new(agent_marseille, tool_paris)
  end

  test 'should refute show with wrong organisation' do
    refute @wrongPolicy.show?
  end
end
