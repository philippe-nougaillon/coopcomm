# frozen_string_literal: true

require 'test_helper'

class AdherentDashboardPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    @policy = DashboardPolicy.new(adherent, nil)
  end

  test 'accès autorisé pour un adhérent sur le tableau de bord' do
    assert @policy.index?
  end

  test 'accès interdit pour un adhérent sur le tableau de bord' do
    refute @policy.reservations_du_jour?
  end
end
