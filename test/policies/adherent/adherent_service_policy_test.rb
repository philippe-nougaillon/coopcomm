# frozen_string_literal: true

require 'test_helper'

class AdherentServicePolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    service = services(:service_paris)

    @policy = ServicePolicy.new(adherent, service)
  end

  test 'accès interdit pour un adhérent sur un service de son organisation' do
    refute @policy.show?
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end
end
