# frozen_string_literal: true

require 'test_helper'

# L'index et la suppression depuis l'administration sont réservés au super_admin,
# donc hors périmètre. Restent les deux parcours ouverts au public : l'inscription
# depuis la page d'accueil et le lien de désinscription des mails.
class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newsletter = newsletters(:bond)
  end

  test 'une inscription est supprimée depuis le lien de désinscription' do
    assert_difference('Newsletter.count', -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to root_url
  end

  test 'un identifiant d’inscription inconnu redirige sans planter' do
    assert_no_difference('Newsletter.count') do
      delete newsletter_url(id: 0)
    end

    assert_redirected_to root_path
  end

  test 'l’inscription d’une adresse inédite est enregistrée' do
    assert_difference('Newsletter.count') do
      get new_newsletter_url, params: { email: "autre-#{@newsletter.email}" }
    end

    assert_response :success
  end

  test 'une adresse déjà inscrite est signalée sans créer de doublon' do
    assert_no_difference('Newsletter.count') do
      get new_newsletter_url(email: @newsletter.email)
    end

    assert_response :success
    assert_match(/existe déjà une inscription/i, response.body)
  end
end
