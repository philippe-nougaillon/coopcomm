# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfCotationTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @cotation = cotations(:cotation_paris)
  end

  test 'document_title : un devis → le titre du document et sa référence' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, "Cotation / Devis n°#{@cotation.ref}"
  end

  test 'document_lignes_association : un devis → ses propres lignes sont imprimées' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_match(/#{@cotation.cotation_lignes.first.intitulé}/i, texte)
  end
end
