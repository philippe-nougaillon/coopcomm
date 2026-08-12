# frozen_string_literal: true

require 'test_helper'

class AgentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    @policy = PagesPolicy.new(agent, nil)
  end

  test 'accès autorisé pour un agent sur les pages sans record' do
    assert @policy.home?
    assert @policy.meteo?
    assert @policy.meteo_by_day?
  end

  test 'accès interdit pour un agent sur les pages sans record' do
    refute @policy.assistant?
    refute @policy.dashboard?
  end
end
