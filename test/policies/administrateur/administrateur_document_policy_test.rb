# frozen_string_literal: true

require 'test_helper'

class AdministrateurDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(administrateur, document)
  end

  test "accès autorisé pour un administrateur sur un document d'un outil de son organisation" do
    assert @policy.valider?
    assert @policy.refuser?
  end
end
