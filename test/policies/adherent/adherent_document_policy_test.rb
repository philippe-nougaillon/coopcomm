# frozen_string_literal: true

require 'test_helper'

class AdherentDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(adherent, document)
  end

  test "accès interdit pour un adhérent sur un document d'un outil de son organisation" do
    refute @policy.valider?
    refute @policy.refuser?
  end
end
