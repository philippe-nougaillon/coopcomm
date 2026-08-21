# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfCommandeTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @commande = commandes(:commande_paris)
  end

  test 'document_title : une commande → le titre du document et sa référence' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, "Commande n°#{@commande.ref}"
  end

  test 'document_lignes_association : une commande → ses propres lignes sont imprimées' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_match(/#{@commande.commande_lignes.first.intitulé}/i, texte)
  end
end
