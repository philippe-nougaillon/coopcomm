# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

# Classe mère des PDF de devis, commande et facture — les documents envoyés aux
# communes. Elle n'est pas instanciable seule : son contenu s'observe à travers
# une sous-classe, dont on prend celle qui porte le trait visé par le test.
class TransformToPdfBasePdfForCrmTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @cotation = cotations(:cotation_paris)
    @commande = commandes(:commande_paris)
    @facture  = factures(:facture_paris)
  end

  # ==================== TESTS CRITIQUES ====================
  # Tout ce qui touche à l'argent : le total imprimé, le détail des lignes, et
  # la distinction entre prix unitaire et total de ligne.

  test 'add_metadata et add_lignes : un devis à 76,50 € → le total est imprimé aux deux emplacements (critique)' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_equal 76.50, @cotation.total_ht.to_f, 'garde : fixture attendue à 76,50'
    assert_equal 2, texte.scan('Total HT : 76,50 €').size
  end

  test 'add_lignes : une ligne ajoutée → le total imprimé suit la somme des lignes (critique)' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: 'Tonte mensuelle', qté: 2)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_equal 136.50, @cotation.total_ht.to_f, 'garde : 76,50 + (30,00 × 2)'
    assert_equal 2, texte.scan('Total HT : 136,50 €').size
  end

  test 'add_lignes : deux lignes → chacune porte son code et son intitulé (critique)' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: 'Tonte mensuelle', qté: 2)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_includes texte, 'NET01'
    assert_match(/Nettoyage hebdomadaire/i, texte)
    assert_includes texte, 'EV01'
    assert_match(/Tonte mensuelle/i, texte)
  end

  test 'add_lignes : une ligne de 3 × 25,50 € → le prix unitaire et le total de ligne sont distincts (critique)' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, '25,50 €', 'prix unitaire de la prestation'
    assert_includes texte, '76,50 €', 'total de la ligne (25,50 × 3)'
  end

  test 'call : une facture d’une autre organisation → aucune donnée d’un autre document (critique)' do
    texte = texte_pdf(TransformToPdf::Facture.call(factures(:facture_marseille)))

    assert_match(/Devis Marseille/i, texte)
    assert_no_match(/Devis nettoyage trimestriel/i, texte)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'document_title : appelé sur la classe mère → non implémenté' do
    erreur = assert_raises(NotImplementedError) do
      TransformToPdf::BasePdfForCrm.new(@cotation).send(:document_title)
    end

    assert_includes erreur.message, 'document_title'
  end

  test 'document_lignes_association : appelé sur la classe mère → non implémenté' do
    erreur = assert_raises(NotImplementedError) do
      TransformToPdf::BasePdfForCrm.new(@cotation).send(:document_lignes_association)
    end

    assert_includes erreur.message, 'document_lignes_association'
  end

  test 'add_metadata : un devis → la référence, le statut, l’adhérent, le service et l’intitulé' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_match(/Réf : #{@cotation.ref}/, texte)
    assert_match(/Statut : Créé/i, texte)
    assert_match(/Adhérent : Weil/i, texte)
    assert_match(/Service : Informatique/i, texte)
    assert_match(/Intitulé : Devis nettoyage trimestriel/i, texte)
  end

  test 'call : un document accentué → les accents et le symbole euro sont lisibles' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, 'Réf'
    assert_includes texte, 'Adhérent'
    assert_includes texte, 'Qté'
    assert_includes texte, '€'
  end

  test 'add_metadata : une date de livraison souhaitée → elle est imprimée' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, I18n.l(@commande.date_livraison_souhaitée, format: :long).capitalize
  end

  test 'add_metadata : aucune date de livraison souhaitée → un tiret est imprimé' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_nil @cotation.date_livraison_souhaitée, 'garde : fixture sans date de livraison'
    assert_includes texte, 'Livraison souhaitée : —'
  end

  test 'add_memo : un mémo renseigné → la section est imprimée' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_includes texte, 'Mémo'
    assert_includes texte, 'Prévoir un accès badge le matin'
  end

  test 'add_memo : aucun mémo → la section n’est pas imprimée' do
    texte = texte_pdf(TransformToPdf::Facture.call(@facture))

    assert_predicate @facture.mémo, :blank?, 'garde : fixture sans mémo'
    assert_no_match(/Mémo/, texte)
  end

  test 'add_signature : un devis signé → la signature, le nom du signataire et la date' do
    @cotation.update_columns(signature: signature_svg, signee_le: Time.zone.parse('2026-06-15 10:00'))

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_includes texte, 'Signature'
    assert_match(/Signé par .*Weil/i, texte)
    assert_includes texte, I18n.l(@cotation.signee_le.to_date, format: :long)
  end

  test 'add_signature : aucune signature → la section n’est pas imprimée' do
    texte = texte_pdf(TransformToPdf::Commande.call(@commande))

    assert_no_match(/Signature/, texte)
  end

  test 'add_footer : un document quelconque → le pied de page porte la date de génération' do
    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation))

    assert_includes texte, "Document généré le #{I18n.l(Time.current, format: :long)}"
  end

  test 'add_lignes : un document sans ligne → le total est imprimé à zéro' do
    cotation = cotations(:cotation_secretariat)

    texte = texte_pdf(TransformToPdf::Cotation.call(cotation))

    assert_empty cotation.cotation_lignes, 'garde : fixture sans ligne'
    assert_includes texte, 'Prestations'
    assert_includes texte, '0,00 €'
  end

  test 'add_lignes : une ligne sans intitulé propre → le libellé de la prestation est imprimé' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: nil, qté: 1)

    texte = texte_pdf(TransformToPdf::Cotation.call(@cotation.reload))

    assert_match(/Entretien des espaces verts/i, texte)
  end

  private

  # Le pad de signature transmet un SVG encodé en base64 dans une data URI.
  def signature_svg
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><path d="M0 0 L10 10" stroke="black"/></svg>'

    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end
end
