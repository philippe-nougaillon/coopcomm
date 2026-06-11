# frozen_string_literal: true

require 'test_helper'

class ManagerDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(manager_paris, document)
  end

  # Valider
  test 'accès manager document valider autorisé' do
    assert @policy.valider?
  end

  # Refuser
  test 'accès manager document refuser autorisé' do
    assert @policy.refuser?
  end
end
