# frozen_string_literal: true

require 'test_helper'

class ManagerServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    service = services(:service_paris)

    @policy = ServicePolicy.new(manager, service)
  end

  test 'accès interdit pour un manager sur un service de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end
end
