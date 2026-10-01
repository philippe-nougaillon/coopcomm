# frozen_string_literal: true

require 'test_helper'

class WarehousesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @warehouse = warehouses(:entrepot_paris)
    sign_in users(:administrateur_paris)
  end

  test 'un site est affiché avec succès' do
    get warehouse_url(@warehouse)

    assert_response :success
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_warehouse_url

    assert_response :success
  end

  test "le formulaire de création ne propose que les non-adhérents des services de l'utilisateur connecté" do
    get new_warehouse_url

    assert_includes assigns(:users), users(:bond)
    assert_not_includes assigns(:users), users(:weil)
    assert_not_includes assigns(:users), users(:agent_marseille)
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_warehouse_url(@warehouse)

    assert_response :success
  end

  test 'un site est créé lorsque les paramètres sont valides' do
    assert_difference('Warehouse.count') do
      post warehouses_url, params: { warehouse: { address: @warehouse.address, name: 'Nouveau site',
                                                  latitude: '1.234', longitude: '5.678' } }
    end

    assert_redirected_to admin_parametres_path(tab: 'sites')
  end

  test "un site sans adresse n'est pas créé" do
    assert_no_difference('Warehouse.count') do
      post warehouses_url, params: { warehouse: { name: 'Sans adresse' } }
    end

    assert_response :unprocessable_content
  end

  test 'un site est modifié lorsque les paramètres sont valides' do
    patch warehouse_url(@warehouse),
          params: { warehouse: { address: '7 Rue Francis de Pressensé, 75014 Paris',
                                 name: 'Entrepôt de Paris', latitude: '2.345', longitude: '6.789' } }

    assert_redirected_to admin_parametres_path(tab: 'sites')
    assert_equal '7 Rue Francis de Pressensé, 75014 Paris', @warehouse.reload.address
  end

  test "un site dont l'adresse est vidée n'est pas modifié" do
    patch warehouse_url(@warehouse), params: { warehouse: { address: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @warehouse.reload.address
  end

  test 'un site est supprimé' do
    assert_difference('Warehouse.count', -1) do
      delete warehouse_url(@warehouse)
    end

    assert_redirected_to admin_parametres_path(tab: 'sites')
  end

  test 'un slug de site inconnu redirige sans planter' do
    get edit_warehouse_url('site-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
