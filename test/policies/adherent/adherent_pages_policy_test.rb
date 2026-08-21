# frozen_string_literal: true

require 'test_helper'

class AdherentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    @policy = PagesPolicy.new(adherent, nil)
  end

  test 'accès autorisé pour un adhérent sur les pages sans record' do
    assert @policy.dashboard?
    assert @policy.home?
    assert @policy.meteo?
    assert @policy.meteo_by_day?
  end

  test 'accès interdit pour un adhérent sur les pages sans record' do
    refute @policy.assistant?
  end
end
