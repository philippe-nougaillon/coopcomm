# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfQrcodeModeleInterventionTest < ActiveSupport::TestCase
  include LecturePdf
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @intervention_modèle = interventions(:intervention_repete)
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le QRCode est réellement dessiné sur l’affiche (critique)' do
    qrcode = RQRCode::QRCode.new(charge_utile_du_qrcode(@intervention_modèle))

    assert_operator rectangles_remplis(pdf_qrcode_genere(@intervention_modèle)), :>, qrcode.modules.size,
                    'le QRCode doit dessiner plus de rectangles que sa matrice n’a de lignes'
  end

  test 'une affiche ne porte pas le logo d’une autre organisation (critique)' do
    organisations(:mairie_paris).logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    assert_includes dimensions_images_pdf(pdf_qrcode_genere(interventions(:nettoyage_port))), DIMENSIONS_LOGO_COOPCOMM
    refute_includes dimensions_images_pdf(pdf_qrcode_genere(interventions(:nettoyage_port))), DIMENSIONS_LOGO_ORGANISATION
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la description du modèle est imprimée en capitales' do
    assert_includes texte_pdf(pdf_qrcode_genere(@intervention_modèle)), @intervention_modèle.description.upcase
  end

  test 'l’affiche invite à scanner' do
    assert_includes texte_pdf(pdf_qrcode_genere(@intervention_modèle)), 'Scanner pour accéder'
  end

  test 'le logo de l’organisation est intégré à l’affiche dans un cadre de 90 points de haut' do
    @intervention_modèle.organisation.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    document = pdf_qrcode_genere(@intervention_modèle)

    assert_includes dimensions_images_pdf(document), DIMENSIONS_LOGO_ORGANISATION
    assert_includes tailles_images_pdf(document), [180.0, 90.0]
  end

  test 'sans logo d’organisation, le logo de CoopComm est intégré à l’affiche' do
    assert_includes dimensions_images_pdf(pdf_qrcode_genere(@intervention_modèle)), DIMENSIONS_LOGO_COOPCOMM
  end

  test 'le pied de page porte la date de création' do
    assert_includes texte_pdf(pdf_qrcode_genere(@intervention_modèle)), "Créé le #{I18n.l(Date.current, format: :long)}"
  end

  private

  def pdf_qrcode_genere(intervention)
    TransformToPdf::QrcodeModeleIntervention.call(intervention)
  end

  # Le QRCode est dessiné en rectangles vectoriels, pas en image : on compte les
  # opérateurs de rectangle du flux PDF plutôt que de chercher un XObject.
  def rectangles_remplis(document)
    document.render.scan(/\d\s+re[\s\n]/).size
  end

  # La charge utile du QRCode n'est lisible ni dans le texte du PDF ni dans le dessin : on
  # l'intercepte à la construction du QRCode, seul mock du fichier.
  def charge_utile_du_qrcode(intervention)
    capturée = nil
    constructeur = RQRCode::QRCode.method(:new)

    RQRCode::QRCode.stub(:new, lambda { |contenu, **options|
      capturée = contenu
      constructeur.call(contenu, **options)
    }) do
      pdf_qrcode_genere(intervention).render
    end

    capturée
  end
end
