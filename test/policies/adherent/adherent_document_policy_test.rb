# frozen_string_literal: true

require 'test_helper'

class AdherentDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(adherent_paris, document)
  end

  # Valider
  test 'accès adhérent document valider interdit' do
    refute @policy.valider?
  end

  # Refuser
  test 'accès adhérent document refuser interdit' do
    refute @policy.refuser?
  end
end
