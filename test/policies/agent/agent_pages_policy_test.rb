# frozen_string_literal: true

require 'test_helper'

class AgentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(agent_paris, nil)
  end

  # Assistant
  test 'accès interdit pour un agent sur la page assistant' do
    refute @policy.assistant?
  end

  # Dashboard
  test 'accès autorisé pour un agent sur la page dashboard' do
    refute @policy.dashboard?
  end

  # Home
  test 'accès autorisé pour un agent sur la page home' do
    assert @policy.home?
  end

  # Meteo
  test 'accès autorisé pour un agent sur la page meteo' do
    assert @policy.meteo?
  end

  # meteo_by_day
  test 'accès autorisé pour un agent sur la page meteo_by_day' do
    assert @policy.meteo_by_day?
  end
end
