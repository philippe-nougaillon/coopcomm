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
end
