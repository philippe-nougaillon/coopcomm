# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfFactureTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @facture = factures(:facture_paris)
  end

  test 'document_title : une facture → le titre du document et sa référence' do
    texte = texte_pdf(TransformToPdf::Facture.call(@facture))

    assert_includes texte, "Facture n°#{@facture.ref}"
  end

  test 'document_lignes_association : une facture → ses propres lignes sont imprimées' do
    texte = texte_pdf(TransformToPdf::Facture.call(@facture))

    assert_match(/#{@facture.facture_lignes.first.intitulé}/i, texte)
  end
end
