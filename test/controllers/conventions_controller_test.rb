# frozen_string_literal: true

require 'test_helper'

class ConventionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    @adherent = users(:patrick_adherent_paris)
    @service = services(:service_paris)
    @convention = conventions(:convention_paris)
    @today = Date.current
    sign_in @admin
  end

  test 'index : sans paramètre → la page répond' do
    get conventions_url

    assert_response :success
  end

  test 'index : recherche sans correspondance → la convention est absente' do
    get conventions_url(search: 'inexistant.pdf')

    assert_response :success
    assert_not_includes assigns(:conventions), @convention
  end

  test 'index : adherent_id → seulement les conventions de cet adhérent' do
    get conventions_url(adherent_id: @convention.user_id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(adherent_id: @adherent.id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'index : service_id → seulement les conventions de ce service' do
    get conventions_url(service_id: services(:informatique).id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(service_id: services(:technique).id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'index : active_on → seulement les conventions actives à cette date' do
    get conventions_url(active_on: @today.beginning_of_year.to_s)
    assert_includes assigns(:conventions), @convention

    get conventions_url(active_on: (@today.beginning_of_year - 1.year).to_s)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'show : une convention de son organisation → la page répond' do
    get convention_url(@convention)

    assert_response :success
    assert_match @convention.user.nom_prénom, response.body
    assert_match @convention.service.nom, response.body
  end

  test 'show : une modification tracée → elle apparaît dans le journal d’activité' do
    @convention.update!(mémo: 'Note de suivi')

    get convention_url(@convention)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Note de suivi/
  end

  test 'new : sans paramètre → la page répond' do
    get new_convention_url

    assert_response :success
  end

  test 'new : avec un adhérent en paramètre → il est préchargé' do
    get new_convention_url(adherent_id: @adherent.slug)

    assert_response :success
    assert_equal @adherent, assigns(:convention).user
  end

  test 'new : par un manager → seuls les adhérents de ses services sont proposés' do
    sign_in users(:hidalgo)

    get new_convention_url

    assert_response :success
    assert_includes assigns(:adherents), users(:weil)
    assert_not_includes assigns(:adherents), users(:adherent_marseille)
  end

  test 'create : paramètres valides → la convention est créée' do
    assert_difference('Convention.count') do
      post conventions_url, params: { convention: {
        user_id: @adherent.id,
        service_id: @service.id,
        date_début: @today.to_s,
        date_fin_prévue: (@today + 1.year).to_s
      } }
    end

    assert_redirected_to conventions_path
  end

  test 'create : doublon adhérent/service → aucune création' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: users(:weil).id, service_id: services(:informatique).id, date_début: @today.to_s
      } }
    end

    assert_response :unprocessable_content
  end

  test 'create : date de fin antérieure au début → aucune création' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: @adherent.id, service_id: @service.id,
        date_début: @today.to_s, date_fin_prévue: (@today - 1.month).to_s
      } }
    end

    assert_response :unprocessable_content
  end

  test 'create : service n’appartenant pas à l’adhérent → aucune création' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: @adherent.id, service_id: services(:informatique).id, date_début: @today.to_s
      } }
    end

    assert_response :unprocessable_content
  end

  test 'destroy : une convention de son organisation → elle est supprimée' do
    assert_difference('Convention.count', -1) do
      delete convention_url(@convention)
    end

    assert_redirected_to conventions_path
  end

  test 'services_for_adherent : un adhérent de son organisation → ses services en JSON' do
    get services_for_adherent_conventions_url(adherent_id: @adherent.id)

    assert_response :success
    assert_includes response.parsed_body.map { |service| service['nom'] }, @service.nom
  end

  test 'services_for_adherent : un adhérent d’une autre organisation → aucun service' do
    get services_for_adherent_conventions_url(adherent_id: users(:adherent_marseille).id)

    assert_response :success
    assert_empty response.parsed_body
  end

  test 'set_convention : un slug inconnu redirige sans planter' do
    get convention_url(id: 'slug-qui-n-existe-pas')

    assert_redirected_to root_path
    assert_equal 'Convention introuvable', flash[:alert]
  end
end
