# frozen_string_literal: true

require 'test_helper'

# La classe mère des PDF de documents impose deux points d'extension aux classes
# filles (Cotation, Commande, Facture).
class TransformToPdfBasePdfForCrmTest < ActiveSupport::TestCase
  setup do
    @base = TransformToPdf::BasePdfForCrm.new(cotations(:cotation_paris))
  end

  test 'document_title doit être implémenté par la classe fille' do
    erreur = assert_raises(NotImplementedError) { @base.send(:document_title) }

    assert_includes erreur.message, 'document_title'
  end

  test 'document_lignes_association doit être implémenté par la classe fille' do
    erreur = assert_raises(NotImplementedError) { @base.send(:document_lignes_association) }

    assert_includes erreur.message, 'document_lignes_association'
  end
end
