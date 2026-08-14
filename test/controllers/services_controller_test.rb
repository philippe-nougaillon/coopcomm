# frozen_string_literal: true

require 'test_helper'

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service = services(:service_paris)
    sign_in users(:administrateur_paris)
  end

  test 'show : un service de son organisation → la page répond' do
    get service_url(@service)

    assert_response :success
  end

  test 'new : sans paramètre → la page répond' do
    get new_service_url

    assert_response :success
  end

  test 'edit : un service de son organisation → la page répond' do
    get edit_service_url(@service)

    assert_response :success
  end

  test 'create : paramètres valides → le service est créé' do
    assert_difference('Service.count') do
      post services_url, params: { service: { nom: "Nouveau #{SecureRandom.uuid}",
                                              organisation_id: organisations(:mairie_paris).id } }
    end

    assert_redirected_to admin_parametres_path(tab: 'services')
  end

  # Un service sans nom se retrouve en entrée VIDE dans le sélecteur du formulaire
  # utilisateur : les comptes qu'on y rattache paraissent sans service.
  test 'critique : create, nom vide → aucune création' do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: '' } }
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit être rempli'
  end

  test 'create : nom déjà pris → aucune création et formulaire réaffiché' do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: services(:technique).nom } }
    end

    assert_response :unprocessable_content
  end

  test 'update : paramètres valides → le service est modifié' do
    nouveau_nom = "Renommé #{SecureRandom.uuid}"

    patch service_url(@service), params: { service: { nom: nouveau_nom,
                                                      organisation_id: organisations(:mairie_paris).id } }

    assert_redirected_to admin_parametres_path(tab: 'services')
    assert_equal nouveau_nom, @service.reload.nom
  end

  test 'critique : update, nom vidé → le service garde son nom' do
    service = services(:technique)

    patch service_url(service), params: { service: { nom: '  ' } }

    assert_response :unprocessable_content
    assert_equal 'Technique', service.reload.nom
  end

  test 'update : nom déjà pris → le service est inchangé' do
    patch service_url(@service), params: { service: { nom: services(:technique).nom } }

    assert_response :unprocessable_content
    assert_not_equal services(:technique).nom, @service.reload.nom
  end

  test 'destroy : un service sans rattachement → il est supprimé' do
    assert_difference('Service.count', -1) do
      delete service_url(services(:menage))
    end

    assert_redirected_to admin_parametres_path(tab: 'services')
  end

  test 'critique : destroy, un service encore rattaché → aucune suppression' do
    assert_no_difference('Service.count') do
      delete service_url(@service)
    end

    assert_redirected_to root_path
    assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
  end

  test 'set_service : un slug inconnu redirige sans planter' do
    get service_url('service-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
