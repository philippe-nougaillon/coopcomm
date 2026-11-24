# frozen_string_literal: true

require 'test_helper'
require_relative '../support/fabrique_pdf'
require_relative '../support/faux_ocr'

class LireDocumentTest < ActiveSupport::TestCase
  include FabriquePdf
  include FauxOcr

  ARTICLE = 'La présente convention a pour objet de définir les modalités de fonctionnement des services communs ' \
            'créés entre la Communauté et la Commune, ainsi que les conditions de remboursement des frais de ' \
            'fonctionnement de ces services, pour un volume annuel de 350 heures.'
  JPEG = "\xFF\xD8\xFF".b

  teardown do
    fermer_pdf
  end

  test 'un document qui n’est pas un PDF est refusé' do
    erreur = assert_raises(LireDocument::Illisible) { LireDocument.call(file_fixture('page_numerisee.png').to_s, 'image/png') }

    assert_equal 'format non pris en charge (image/png)', erreur.message
  end

  test 'le texte d’un PDF est rendu avec son nombre de pages' do
    lecture = LireDocument.call(pdf_de_texte([ARTICLE, ARTICLE]), 'application/pdf')

    assert_includes lecture.texte.squish, 'pour un volume annuel de 350 heures'
    assert_equal 2, lecture.pages
    assert_empty lecture.images
  end

  test 'une numérisation est lue par OCR, page par page et ligne par ligne' do
    lecture = avec_faux_ocr([ARTICLE.split, %w[Fait à Valfictif]]) { LireDocument.call(pdf_numerise(2), 'application/pdf') }

    assert_equal "#{ARTICLE}\nFait à Valfictif\n\n#{ARTICLE}\nFait à Valfictif", lecture.texte
    assert_equal 2, lecture.pages_ocr
    assert_empty lecture.images
  end

  test 'un mot lu avec trop peu de confiance est gardé sous la marque incertain, plusieurs à la suite sous la même' do
    ligne = ARTICLE.split + [['NES', 31], ['x9', 12], 'heures', ['2015', 59.9], ['Mairie', 60]]

    lecture = avec_faux_ocr([ligne]) { LireDocument.call(pdf_numerise(1), 'application/pdf') }

    assert_equal "#{ARTICLE} [incertain : NES x9] heures [incertain : 2015] Mairie", lecture.texte
  end

  test 'une numérisation de plus de huit pages n’est lue par OCR que pour ses huit premières' do
    lecture = avec_faux_ocr([ARTICLE.split]) { LireDocument.call(pdf_numerise(9), 'application/pdf') }

    assert_equal 9, lecture.pages
    assert_equal 8, lecture.pages_ocr
  end

  test 'un PDF presque sans texte est lu comme une numérisation' do
    lecture = avec_faux_ocr([ARTICLE.split]) { LireDocument.call(pdf_de_texte(['Page de garde']), 'application/pdf') }

    assert_equal ARTICLE, lecture.texte
  end

  test 'une numérisation imprimée est lue par le tesseract du poste' do
    assert system('tesseract --list-langs 2>&1 | grep -qx fra'), 'tesseract ou sa langue fra manque : sudo apt install tesseract-ocr tesseract-ocr-fra'

    lecture = LireDocument.call(pdf_numerise_avec_texte(ARTICLE), 'application/pdf')

    assert_includes lecture.texte.squish, 'créés entre la Communauté et la Commune'
    assert_includes lecture.texte.squish, 'pour un volume annuel de 350 heures'
    assert_equal 1, lecture.pages_ocr
  end

  test 'une numérisation dont l’OCR ne tire presque rien est rendue en images' do
    lecture = avec_faux_ocr([%w[Page de garde]]) { LireDocument.call(pdf_numerise(2), 'application/pdf') }

    assert_nil lecture.texte
    assert_nil lecture.pages_ocr
    assert_equal [JPEG, JPEG], lecture.images.map { |image| image[0, 3] }
  end

  test 'les mots incertains ne comptent pas dans le texte tiré par l’OCR' do
    lecture = avec_faux_ocr(Array.new(30) { [['gribouillis', 5]] }) { LireDocument.call(pdf_numerise(1), 'application/pdf') }

    assert_nil lecture.texte
    assert_equal [JPEG], lecture.images.map { |image| image[0, 3] }
  end

  test 'une numérisation dont l’OCR échoue est rendue en images' do
    lecture = avec_ocr_en_panne { LireDocument.call(pdf_numerise(1), 'application/pdf') }

    assert_nil lecture.texte
    assert_equal [JPEG], lecture.images.map { |image| image[0, 3] }
  end

  test 'sans OCR sur le poste, une numérisation est rendue en images, une par page' do
    lecture = sans_ocr { LireDocument.call(pdf_numerise(3), 'application/pdf') }

    assert_nil lecture.texte
    assert_equal 3, lecture.pages
    assert_equal [JPEG, JPEG, JPEG], lecture.images.map { |image| image[0, 3] }
  end

  test 'une numérisation de plus de huit pages n’est rendue en images que pour ses huit premières' do
    lecture = sans_ocr { LireDocument.call(pdf_numerise(9), 'application/pdf') }

    assert_equal 9, lecture.pages
    assert_equal 8, lecture.images.size
  end

  test 'un PDF illisible est refusé' do
    faux_pdf = Tempfile.new(['faux', '.pdf'])
    faux_pdf.write('%PDF-1.4 ceci n’est pas un PDF')
    faux_pdf.flush

    erreur = assert_raises(LireDocument::Illisible) { LireDocument.call(faux_pdf.path, 'application/pdf') }

    assert_equal 'PDF illisible', erreur.message
  ensure
    faux_pdf.close!
  end

  test 'une lecture trop longue est abandonnée' do
    Timeout.stub(:timeout, ->(*) { raise Timeout::Error }) do
      erreur = assert_raises(LireDocument::Illisible) { LireDocument.call(pdf_de_texte([ARTICLE]), 'application/pdf') }

      assert_equal 'lecture du PDF trop longue', erreur.message
    end
  end
end
