# frozen_string_literal: true

require 'test_helper'

class AdministrateurServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    service = services(:service_paris)
    service_supprimable = services(:menage)
    service_autre_org = services(:service_marseille)

    @policy = ServicePolicy.new(administrateur, service)
    @policy_supprimable = ServicePolicy.new(administrateur, service_supprimable)
    @policy_autre_org = ServicePolicy.new(administrateur, service_autre_org)
  end

  test 'accès autorisé pour un administrateur sur un service de son organisation' do
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
  end

  test 'accès interdit pour un administrateur sur un service de son organisation encore rattaché' do
    refute @policy.destroy?
  end

  test 'accès autorisé pour un administrateur sur un service de son organisation sans rattachement' do
    assert @policy_supprimable.destroy?
  end

  test "accès interdit pour un administrateur sur un service d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
