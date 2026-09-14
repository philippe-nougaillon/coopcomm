# frozen_string_literal: true

require 'test_helper'

class ManagerDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(manager, document)
  end

  test "accès autorisé pour un manager sur un document d'un outil de son organisation" do
    assert @policy.valider?
    assert @policy.refuser?
  end
end
