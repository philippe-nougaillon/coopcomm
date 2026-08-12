# frozen_string_literal: true

require 'test_helper'

class AdministrateurPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    @policy = PagesPolicy.new(administrateur, nil)
  end

  test 'accès autorisé pour un administrateur sur les pages sans record' do
    assert @policy.assistant?
    assert @policy.dashboard?
    assert @policy.home?
    assert @policy.meteo?
    assert @policy.meteo_by_day?
  end
end
