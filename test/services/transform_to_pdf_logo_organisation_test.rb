# frozen_string_literal: true

require 'test_helper'

class TransformToPdfLogoOrganisationTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @organisation = organisations(:mairie_paris)
  end

  test 'une organisation sans logo reçoit le logo de CoopComm' do
    assert_equal TransformToPdf::LogoOrganisation::COOPCOMM, TransformToPdf::LogoOrganisation.call(@organisation)
  end

  test 'sans organisation, le logo est celui de CoopComm' do
    assert_equal TransformToPdf::LogoOrganisation::COOPCOMM, TransformToPdf::LogoOrganisation.call(nil)
  end

  test 'le logo de CoopComm est un JPEG, que Prawn embarque sans le décoder' do
    assert_equal Prawn::Images::JPG, Prawn.image_handler.find(File.binread(TransformToPdf::LogoOrganisation::COOPCOMM))
  end

  test 'le logo d’une organisation est rendu en JPEG, à ses dimensions' do
    @organisation.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    octets = TransformToPdf::LogoOrganisation.call(@organisation).read
    image = Vips::Image.new_from_buffer(octets, '')

    assert_equal Prawn::Images::JPG, Prawn.image_handler.find(octets)
    assert_equal [60, 30], [image.width, image.height]
  end

  test 'un logo plus grand que le cadre d’impression est réduit' do
    @organisation.logo.attach(fixture_file_upload('logo_trop_grand.png', 'image/png'))

    image = Vips::Image.new_from_buffer(TransformToPdf::LogoOrganisation.call(@organisation).read, '')

    assert_equal [800, 400], [image.width, image.height]
  end

  test 'la transparence d’un logo devient du blanc' do
    @organisation.logo.attach(fixture_file_upload('logo_transparent.png', 'image/png'))

    image = Vips::Image.new_from_buffer(TransformToPdf::LogoOrganisation.call(@organisation).read, '')

    assert_equal [255.0, 255.0, 255.0], image.getpoint(0, 0)
  end

  test 'un PNG entrelacé, que Prawn refuse tel quel, est rendu lisible' do
    fichier = fixture_file_upload('logo_entrelace.png', 'image/png')
    @organisation.logo.attach(fichier)

    assert_raises(Prawn::Errors::UnsupportedImageType) { Prawn::Document.new.image(fichier.path) }
    assert_nothing_raised { Prawn::Document.new.image(TransformToPdf::LogoOrganisation.call(@organisation)) }
  end

  test 'un logo dont le fichier a disparu du stockage retombe sur le logo de CoopComm' do
    @organisation.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))
    @organisation.logo.blob.service.delete(@organisation.logo.blob.key)

    assert_equal TransformToPdf::LogoOrganisation::COOPCOMM, TransformToPdf::LogoOrganisation.call(@organisation)
  end
end
