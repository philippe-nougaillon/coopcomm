# frozen_string_literal: true

require 'test_helper'

class AdministrateurOrganisationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    organisation = organisations(:mairie_paris)
    organisation_autre = organisations(:mairie_marseille)

    @policy = OrganisationPolicy.new(administrateur, organisation)
    @policy_autre_org = OrganisationPolicy.new(administrateur, organisation_autre)
  end

  test 'accès autorisé pour un administrateur sur son organisation' do
    assert @policy.show?
    assert @policy.update?
    assert @policy.destroy?
  end

  test 'accès interdit pour un administrateur sur une autre organisation (critique)' do
    refute @policy_autre_org.show?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
