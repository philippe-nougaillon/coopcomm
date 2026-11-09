# frozen_string_literal: true

require 'test_helper'

class AdministrateurDashboardPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    @policy = DashboardPolicy.new(administrateur, nil)
  end

  test 'accès autorisé pour un administrateur sur le tableau de bord' do
    assert @policy.index?
    assert @policy.reservations_du_jour?
  end
end
