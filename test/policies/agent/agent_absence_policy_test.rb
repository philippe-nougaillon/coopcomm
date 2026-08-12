# frozen_string_literal: true

require 'test_helper'

class AgentAbsencePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)

    absence = absences(:one)

    @policy = AbsencePolicy.new(agent, absence)
  end

  test 'accès interdit pour un agent sur sa propre absence' do
    refute @policy.create?
    refute @policy.update?
    refute @policy.destroy?
  end
end
