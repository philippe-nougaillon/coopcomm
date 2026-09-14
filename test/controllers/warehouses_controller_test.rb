# frozen_string_literal: true

require 'test_helper'

class WarehousesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @warehouse = warehouses(:entrepot_paris)
    sign_in users(:administrateur_paris)
  end

  test 'show : un site de son organisation → la page répond' do
    get warehouse_url(@warehouse)

    assert_response :success
  end

  test 'new : sans paramètre → la page répond' do
    get new_warehouse_url

    assert_response :success
  end

  test 'new : le formulaire ne propose que les non-adhérents des services du current_user' do
    get new_warehouse_url

    assert_includes assigns(:users), users(:bond)
    assert_not_includes assigns(:users), users(:weil)
    assert_not_includes assigns(:users), users(:agent_marseille)
  end

  test 'edit : un site de son organisation → la page répond' do
    get edit_warehouse_url(@warehouse)

    assert_response :success
  end

  test 'create : paramètres valides → le site est créé' do
    assert_difference('Warehouse.count') do
      post warehouses_url, params: { warehouse: { address: @warehouse.address, name: 'Nouveau site',
                                                  latitude: '1.234', longitude: '5.678' } }
    end

    assert_redirected_to admin_parametres_path(tab: 'sites')
  end

  test 'create : sans adresse → aucune création et formulaire réaffiché' do
    assert_no_difference('Warehouse.count') do
      post warehouses_url, params: { warehouse: { name: 'Sans adresse' } }
    end

    assert_response :unprocessable_content
  end

  test 'update : paramètres valides → le site est modifié' do
    patch warehouse_url(@warehouse),
          params: { warehouse: { address: '7 Rue Francis de Pressensé, 75014 Paris',
                                 name: 'Entrepôt de Paris', latitude: '2.345', longitude: '6.789' } }

    assert_redirected_to admin_parametres_path(tab: 'sites')
    assert_equal '7 Rue Francis de Pressensé, 75014 Paris', @warehouse.reload.address
  end

  test 'update : adresse vidée → formulaire réaffiché en 422 et site inchangé' do
    patch warehouse_url(@warehouse), params: { warehouse: { address: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @warehouse.reload.address
  end

  test 'destroy : un site de son organisation → il est supprimé' do
    assert_difference('Warehouse.count', -1) do
      delete warehouse_url(@warehouse)
    end

    assert_redirected_to admin_parametres_path(tab: 'sites')
  end

  test 'set_warehouse : un slug inconnu redirige sans planter' do
    get edit_warehouse_url('site-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
