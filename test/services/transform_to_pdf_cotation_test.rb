# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfCotationTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @cotation = cotations(:cotation_paris)
  end

  test 'le titre du document porte « Cotation / Devis » et la référence du devis' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, "Cotation / Devis n°#{@cotation.ref}"
  end

  test 'les lignes du devis sont imprimées' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_match(/#{@cotation.cotation_lignes.first.intitulé}/i, texte)
  end
end
