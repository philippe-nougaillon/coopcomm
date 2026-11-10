# frozen_string_literal: true

require 'test_helper'

# Le logo d'un mail se charge depuis le client de messagerie : sans session, et sans compter sur le suivi d'une redirection.
class LogoOrganisationMailTest < ActionDispatch::IntegrationTest
  test "En tant que destinataire d'un mail, je veux voir le logo de l'organisation sans être connecté" do
    organisations(:mairie_paris).logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    get src_du_logo(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test "En tant que destinataire d'un mail d'une organisation sans logo, je veux voir le logo de CoopComm" do
    get src_du_logo(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test "En tant que destinataire d'un mail, je veux recevoir en PNG un logo posé en WebP" do
    organisations(:mairie_paris).logo.attach(fixture_file_upload('logo_organisation.webp', 'image/webp'))
    src = src_du_logo(NotificationMailer.relance(interventions(:intervention_paris)))
    assert_match %r{/logo_organisation\.png\z}, src

    get src

    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  test "En tant que destinataire d'un mail, je veux recevoir le logo réduit à la hauteur de l'en-tête" do
    organisations(:mairie_paris).logo.attach(fixture_file_upload('logo_trop_grand.png', 'image/png'))

    get src_du_logo(NotificationMailer.relance(interventions(:intervention_paris)))

    image = Vips::Image.new_from_buffer(response.body, '')
    assert_equal [360, 180], [image.width, image.height]
  end

  private

  def src_du_logo(mail)
    Nokogiri::HTML((mail.html_part || mail).body.to_s).at_css('.email-header img')['src']
  end
end
