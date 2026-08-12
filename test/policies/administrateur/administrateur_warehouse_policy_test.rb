# frozen_string_literal: true

require 'test_helper'

class AdministrateurWarehousePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    warehouse = warehouses(:entrepot_paris)
    warehouse_autre_org = warehouses(:entrepot_marseille)

    @policy = WarehousePolicy.new(administrateur, warehouse)
    @policy_autre_org = WarehousePolicy.new(administrateur, warehouse_autre_org)
  end

  test 'accès autorisé pour un administrateur sur un site de son organisation' do
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès interdit pour un administrateur sur un site d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
