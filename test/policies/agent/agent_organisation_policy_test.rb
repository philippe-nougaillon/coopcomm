# frozen_string_literal: true

require 'test_helper'

class AgentOrganisationPolicyTest < ActionDispatch::IntegrationTest
  # Le controller organisation n'a pas de page activé, donc pas de policy

  # def setup
  #   agent_paris = users(:martin_technique_paris)

  #   organisation = organisations(:mairie_paris)

  #   @policy = OrganisationPolicy.new(agent_paris, organisation)
  # end

  # # Show
  # test "accès interdit pour un agent avec le show d'une organisation" do
  #   refute @policy.show?
  # end

  # # Edit
  # test "accès interdit pour un agent avec l'edit d'une organisation" do
  #   refute @policy.edit?
  # end

  # # Update
  # test "accès interdit pour un agent avec l'update d'une organisation" do
  #   refute @policy.update?
  # end
end
