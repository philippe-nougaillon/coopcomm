# frozen_string_literal: true

require 'test_helper'

class ManagerPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    @policy = PagesPolicy.new(manager, nil)
  end

  test 'accès autorisé pour un manager sur les pages sans record' do
    assert @policy.dashboard?
    assert @policy.home?
    assert @policy.meteo?
    assert @policy.meteo_by_day?
  end

  test 'accès interdit pour un manager sur les pages sans record' do
    refute @policy.assistant?
  end
end
