# frozen_string_literal: true

require 'test_helper'

class ManagerPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:hidalgo)

    prestation = prestations(:nettoyage_bureaux)

    @policy = PrestationPolicy.new(@manager, prestation)
  end

  test 'accès interdit pour un manager sur une prestation de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test 'scope : un manager ne voit que les prestations de son organisation' do
    scope = PrestationPolicy::Scope.new(@manager, Prestation.all).resolve

    assert_includes scope, prestations(:nettoyage_bureaux)
    refute_includes scope, prestations(:prestation_marseille)
  end
end
