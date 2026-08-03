# frozen_string_literal: true

require 'test_helper'

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service = services(:service_paris)
    sign_in users(:administrateur_paris)
  end

  test 'should not get index' do
    get services_url
    assert_response :not_found
  end

  test 'should get new' do
    get new_service_url
    assert_response :success
  end

  test 'should create service' do
    assert_difference('Service.count') do
      post services_url,
           params: { service: { nom: @service.nom + SecureRandom.uuid,
                                organisation_id: organisations(:mairie_paris).id } }
    end

    assert_redirected_to service_url(Service.last)
  end

  test 'should show service' do
    get service_url(@service)
    assert_response :success
  end

  test 'should edit service' do
    get edit_service_url(@service)
    assert_response :success
  end

  test 'should update service' do
    patch service_url(@service),
          params: { service: { nom: @service.nom + SecureRandom.uuid,
                               organisation_id: organisations(:mairie_paris).id } }
    assert_redirected_to service_url(@service)
  end

  test 'should destroy service' do
    assert_difference('Service.count', -1) do
      delete service_url(@service)
    end

    assert_redirected_to admin_parametres_url
  end

  # --- create / update : branches d'échec ---

  # Un service sans nom se retrouve en entrée VIDE dans le sélecteur de services du
  # formulaire utilisateur ; les comptes qu'on y rattache paraissent sans service.
  test 'critique : un service sans nom n’est pas créé' do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: '' } }
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit être rempli'
  end

  test 'critique : un service existant ne peut pas être renommé en vide' do
    service = services(:technique)

    patch service_url(service), params: { service: { nom: '  ' } }

    assert_response :unprocessable_content
    assert_equal 'Technique', service.reload.nom
  end

  test 'create d\'un service au nom déjà pris réaffiche le formulaire en 422' do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: services(:technique).nom } }
    end

    assert_response :unprocessable_content
  end

  test 'create d\'un service au nom déjà pris en JSON renvoie les erreurs' do
    post services_url, params: { service: { nom: services(:technique).nom } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'déjà'
  end

  test 'update vers un nom déjà pris réaffiche le formulaire en 422' do
    patch service_url(@service), params: { service: { nom: services(:technique).nom } }

    assert_response :unprocessable_content
    assert_not_equal services(:technique).nom, @service.reload.nom
  end

  test 'update vers un nom déjà pris en JSON renvoie les erreurs' do
    patch service_url(@service), params: { service: { nom: services(:technique).nom } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'déjà'
  end

  test 'un slug de service inconnu redirige au lieu de planter' do
    get service_url('service-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end

end
