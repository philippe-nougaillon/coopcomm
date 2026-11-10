# frozen_string_literal: true

require 'test_helper'

class ManagerOrganisationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    organisation = organisations(:mairie_paris)

    @policy = OrganisationPolicy.new(manager, organisation)
  end

  test 'accès interdit pour un manager sur son organisation' do
    refute @policy.show?
    refute @policy.update?
    refute @policy.destroy?
  end
end
