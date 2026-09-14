# frozen_string_literal: true

require 'test_helper'

# L'index et la suppression depuis l'administration sont réservés au super_admin,
# donc hors périmètre. Restent les deux parcours ouverts au public : l'inscription
# depuis la page d'accueil et le lien de désinscription des mails.
class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newsletter = newsletters(:bond)
  end

  test 'destroy : depuis le lien de désinscription → l’inscription est supprimée' do
    assert_difference('Newsletter.count', -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to root_url
  end

  test 'set_newsletter : un identifiant inconnu redirige sans planter' do
    assert_no_difference('Newsletter.count') do
      delete newsletter_url(id: 0)
    end

    assert_redirected_to root_path
  end

  test 'new : une adresse inédite → l’inscription est enregistrée' do
    assert_difference('Newsletter.count') do
      get new_newsletter_url, params: { email: "autre-#{@newsletter.email}" }
    end

    assert_response :success
  end

  test 'new : une adresse déjà connue → signalée sans doublon' do
    assert_no_difference('Newsletter.count') do
      get new_newsletter_url(email: @newsletter.email)
    end

    assert_response :success
    assert_match(/existe déjà une inscription/i, response.body)
  end
end
