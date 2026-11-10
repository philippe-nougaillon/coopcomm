# frozen_string_literal: true

require 'test_helper'

class AdherentOrganisationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    organisation = organisations(:mairie_paris)

    @policy = OrganisationPolicy.new(adherent, organisation)
  end

  test 'accès interdit pour un adhérent sur son organisation' do
    refute @policy.show?
    refute @policy.update?
    refute @policy.destroy?
  end
end
