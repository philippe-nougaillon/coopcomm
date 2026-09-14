# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfCommandeTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @commande = commandes(:commande_paris)
  end

  test 'le titre du document porte « Commande » et la référence de la commande' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, "Commande n°#{@commande.ref}"
  end

  test 'les lignes de la commande sont imprimées' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_match(/#{@commande.commande_lignes.first.intitulé}/i, texte)
  end
end
