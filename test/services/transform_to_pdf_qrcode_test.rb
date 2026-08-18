# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

# Affiche QRCode d'un modèle de pointage — le premier maillon du parcours le
# plus utilisé (quatre scans par agent et par jour). Si l'URL encodée cesse de
# pointer sur la bonne intervention, plus aucun pointage ne fonctionne et rien
# dans la suite ne le signale : le contrôleur n'asserte que le type MIME.
class TransformToPdfQrcodeTest < ActiveSupport::TestCase
  include LecturePdf
  include Rails.application.routes.url_helpers

  setup do
    @modèle = interventions(:intervention_repete)
    @hôte   = Rails.application.config.default_url_options[:host]
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le QRCode encode l’URL de pointage de cette intervention (critique)' do
    assert_equal pointer_intervention_url(@modèle, host: @hôte), charge_utile_du_qrcode(@modèle)
  end

  test 'deux interventions donnent deux QRCodes différents (critique)' do
    autre = interventions(:intervention_fille)

    assert_not_equal charge_utile_du_qrcode(@modèle), charge_utile_du_qrcode(autre)
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==================== Lisibilité de l'affiche ====================

  test 'la description est imprimée en capitales' do
    texte = texte_pdf(TransformToPdf::QrcodeModeleIntervention.call(@modèle))

    assert_includes texte, @modèle.description.upcase
  end

  test 'l’affiche invite à scanner' do
    texte = texte_pdf(TransformToPdf::QrcodeModeleIntervention.call(@modèle))

    assert_includes texte, 'Scanner pour accéder'
  end

  test 'le pied de page porte la date de création' do
    texte = texte_pdf(TransformToPdf::QrcodeModeleIntervention.call(@modèle))

    assert_includes texte, "Créé le #{I18n.l(Date.current, format: :long)}"
  end

  private

  # La charge utile n'est lisible ni dans le texte du PDF ni dans l'image
  # rendue : on l'intercepte à la construction du QRCode, seul mock du fichier.
  def charge_utile_du_qrcode(intervention)
    capturée = nil
    constructeur = RQRCode::QRCode.method(:new)

    RQRCode::QRCode.stub(:new, lambda { |contenu, **options|
      capturée = contenu
      constructeur.call(contenu, **options)
    }) do
      TransformToPdf::QrcodeModeleIntervention.call(intervention).render
    end

    capturée
  end
end
