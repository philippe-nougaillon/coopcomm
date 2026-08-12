# frozen_string_literal: true

require 'test_helper'

class AgentDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(agent, document)
  end

  test "accès interdit pour un agent sur un document d'un outil de son organisation" do
    refute @policy.valider?
    refute @policy.refuser?
  end
end
