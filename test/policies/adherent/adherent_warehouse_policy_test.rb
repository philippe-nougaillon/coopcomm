# frozen_string_literal: true

require 'test_helper'

class AdherentWarehousePolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:weil)

    warehouse = warehouses(:entrepot_paris)

    @policy = WarehousePolicy.new(utilisateur, warehouse)
  end

  test 'accès interdit pour un adhérent sur un site de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end
end
