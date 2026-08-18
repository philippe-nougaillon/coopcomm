# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

# Contenu réel des PDF de devis, commande et facture — les documents envoyés
# aux communes. Les tests contrôleur n'assertent que le type MIME : un montant
# faux, une colonne inversée ou un adhérent mélangé passerait sans bruit.
class TransformToPdfDocumentsTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @cotation = cotations(:cotation_paris)   # 1 ligne : NET01, qté 3 × 25,50 = 76,50
    @commande = commandes(:commande_paris)
    @facture  = factures(:facture_paris)
  end

  # ==================== TESTS CRITIQUES ====================
  # Tout ce qui touche à l'argent : le total imprimé, le détail des lignes, et
  # la distinction entre prix unitaire et total de ligne.

  # Le total figure deux fois — en métadonnées et sous le tableau. Les compter
  # empêche qu'un seul des deux emplacements dérive : un document qui
  # s'auto-contredit sur son montant est le pire des cas.
  test 'le total imprimé est celui de l’enregistrement, aux deux emplacements (critique)' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_equal 76.50, @cotation.total_ht.to_f, 'garde : fixture attendue à 76,50'
    assert_equal 2, texte.scan('Total HT : 76,50 €').size
  end

  test 'le total imprimé suit la somme des lignes quand une ligne est ajoutée (critique)' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: 'Tonte mensuelle', qté: 2)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_equal 136.50, @cotation.total_ht.to_f, 'garde : 76,50 + (30,00 × 2)'
    assert_equal 2, texte.scan('Total HT : 136,50 €').size
  end

  test 'chaque ligne est imprimée avec son code, son intitulé, sa quantité et ses montants (critique)' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: 'Tonte mensuelle', qté: 2)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_includes texte, 'NET01'
    assert_match(/Nettoyage hebdomadaire/i, texte)
    assert_includes texte, 'EV01'
    assert_match(/Tonte mensuelle/i, texte)
  end

  test 'le prix unitaire et le total de la ligne sont imprimés distinctement (critique)' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, '25,50 €', 'prix unitaire de la prestation'
    assert_includes texte, '76,50 €', 'total de la ligne (25,50 × 3)'
  end

  test 'un document ne contient pas les données d’un autre document (critique)' do
    texte = texte_pdf(TransformToPdf::Facture.call(factures(:facture_marseille)))

    assert_match(/Devis Marseille/i, texte)
    assert_no_match(/Devis nettoyage trimestriel/i, texte)
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==================== En-tête et métadonnées ====================

  test 'le titre distingue le devis, la commande et la facture' do
    assert_includes texte_pdf(TransformToPdf::Cotation.call(@cotation)), "Cotation / Devis n°#{@cotation.ref}"
    assert_includes texte_pdf(TransformToPdf::Commande.call(@commande)), "Commande n°#{@commande.ref}"
    assert_includes texte_pdf(TransformToPdf::Facture.call(@facture)), "Facture n°#{@facture.ref}"
  end

  test 'les métadonnées identifient la référence, le statut, l’adhérent, le service et l’intitulé' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_match(/Réf : #{@cotation.ref}/, texte)
    assert_match(/Statut : Créé/i, texte)
    assert_match(/Adhérent : Weil/i, texte)
    assert_match(/Service : Informatique/i, texte)
    assert_match(/Intitulé : Devis nettoyage trimestriel/i, texte)
  end

  test 'les accents et le symbole euro sont lisibles' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, 'Réf'
    assert_includes texte, 'Adhérent'
    assert_includes texte, 'Qté'
    assert_includes texte, '€'
  end

  test 'la date de livraison souhaitée est imprimée quand elle est renseignée' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, I18n.l(@commande.date_livraison_souhaitée, format: :long).capitalize
  end

  test 'sans date de livraison souhaitée, un tiret est imprimé' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_nil @cotation.date_livraison_souhaitée, 'garde : fixture sans date de livraison'
    assert_includes texte, 'Livraison souhaitée : —'
  end

  # ==================== Sections optionnelles ====================

  test 'le mémo est imprimé quand il est renseigné' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, 'Mémo'
    assert_includes texte, 'Prévoir un accès badge le matin'
  end

  test 'sans mémo, la section n’est pas imprimée' do
    texte = texte_pdf(TransformToPdf::Facture.call(@facture))

    assert_predicate @facture.mémo, :blank?, 'garde : fixture sans mémo'
    assert_no_match(/Mémo/, texte)
  end

  test 'une cotation signée porte la signature, le nom du signataire et la date' do
    @cotation.update_columns(signature: signature_svg, signee_le: Time.zone.parse('2026-06-15 10:00'))

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_includes texte, 'Signature'
    assert_match(/Signé par .*Weil/i, texte)
    assert_includes texte, I18n.l(@cotation.signee_le.to_date, format: :long)
  end

  test 'un document sans signature n’a pas de section Signature' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_no_match(/Signature/, texte)
  end

  # ==================== Cas limites ====================

  test 'un document sans ligne s’imprime avec un total à zéro' do
    cotation = cotations(:cotation_secretariat)

    texte = texte_pdf(TransformToPdf::Cotation.call(cotation))

    assert_empty cotation.cotation_lignes, 'garde : fixture sans ligne'
    assert_includes texte, 'Prestations'
    assert_includes texte, '0,00 €'
  end

  test 'une ligne sans intitulé propre retombe sur le libellé de la prestation' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: nil, qté: 1)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_match(/Entretien des espaces verts/i, texte)
  end

  test 'la classe mère refuse d’être utilisée directement' do
    assert_raises(NotImplementedError) { TransformToPdf::BasePdfForCrm.call(@cotation) }
  end

  private

  # Le pad de signature transmet un SVG encodé en base64 dans une data URI.
  def signature_svg
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><path d="M0 0 L10 10" stroke="black"/></svg>'

    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end
end
