# frozen_string_literal: true

require 'test_helper'

class ManagerDashboardPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    @policy = DashboardPolicy.new(manager, nil)
  end

  test 'accès autorisé pour un manager sur le tableau de bord' do
    assert @policy.index?
    assert @policy.reservations_du_jour?
  end
end
