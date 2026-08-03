# frozen_string_literal: true

require 'test_helper'

class WarehousesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @warehouse = warehouses(:entrepot_paris)
    sign_in users(:administrateur_paris)
  end

  test 'should not get index' do
    get warehouses_url
    assert_response :not_found
  end

  test 'should get new' do
    get new_warehouse_url
    assert_response :success
  end

  test 'should create warehouse' do
    assert_difference('Warehouse.count') do
      post warehouses_url,
           params: { warehouse: { address: @warehouse.address, name: @warehouse.name, latitude: '1.234',
                                  longitude: '5.678' } }
    end

    assert_redirected_to admin_parametres_path(tab: "sites")
  end

  test 'should show warehouse' do
    get warehouse_url(@warehouse)
    assert_response :success
  end

  test 'should get edit' do
    get edit_warehouse_url(@warehouse)
    assert_response :success
  end

  test 'should update warehouse' do
    patch warehouse_url(@warehouse),
          params: { warehouse: { address: '7 Rue Francis de Pressensé, 75014 Paris', name: 'Entrepôt de Paris',
                                 latitude: '2.345', longitude: '6.789' } }
    assert_redirected_to admin_parametres_path(tab: "sites")
  end

  test 'should destroy warehouse' do
    assert_difference('Warehouse.count', -1) do
      delete warehouse_url(@warehouse)
    end

    assert_redirected_to admin_parametres_path(tab: "sites")
  end

  # --- update : branches d'échec / slug inconnu ---

  test 'update invalide réaffiche le formulaire en 422' do
    patch warehouse_url(@warehouse), params: { warehouse: { address: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @warehouse.reload.address
  end

  test 'update invalide en JSON renvoie les erreurs' do
    patch warehouse_url(@warehouse), params: { warehouse: { address: '' } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end

  test 'un slug de site inconnu redirige au lieu de planter' do
    get edit_warehouse_url('site-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
