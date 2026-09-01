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

  test 'la liste des conventions est affichée avec succès' do
    get conventions_url

    assert_response :success
  end

  test 'la recherche dans la liste ne retourne que les conventions correspondantes' do
    get conventions_url(search: 'inexistant.pdf')

    assert_response :success
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par adhérent ne retourne que les conventions de cet adhérent' do
    get conventions_url(adherent_id: @convention.user_id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(adherent_id: @adherent.id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par service ne retourne que les conventions de ce service' do
    get conventions_url(service_id: services(:informatique).id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(service_id: services(:technique).id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par date ne retourne que les conventions actives à cette date' do
    get conventions_url(active_on: @today.beginning_of_year.to_s)
    assert_includes assigns(:conventions), @convention

    get conventions_url(active_on: (@today.beginning_of_year - 1.year).to_s)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'une convention est affichée avec succès' do
    get convention_url(@convention)

    assert_response :success
    assert_match @convention.user.nom_prénom, response.body
    assert_match @convention.service.nom, response.body
  end

  test 'une modification de convention apparaît dans son journal d’activité' do
    @convention.update!(mémo: 'Note de suivi')

    get convention_url(@convention)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Note de suivi/
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_convention_url

    assert_response :success
  end

  test 'les heures conventionnées sont vides dans le formulaire de création' do
    get new_convention_url

    assert_response :success
    assert_nil assigns(:convention).heures_conventionnees
  end

  test 'l’adhérent passé en paramètre est préchargé dans le formulaire de création' do
    get new_convention_url(adherent_id: @adherent.slug)

    assert_response :success
    assert_equal @adherent, assigns(:convention).user
  end

  test 'un manager ne se voit proposer que les adhérents de ses services' do
    sign_in users(:hidalgo)

    get new_convention_url

    assert_response :success
    assert_includes assigns(:adherents), users(:weil)
    assert_not_includes assigns(:adherents), users(:adherent_marseille)
  end

  test 'une convention est créée lorsque les paramètres sont valides' do
    assert_difference('Convention.count') do
      post conventions_url, params: { convention: {
        user_id: @adherent.id,
        service_id: @service.id,
        date_début: @today.to_s,
        date_fin_prévue: (@today + 1.year).to_s,
        heures_conventionnees: 100
      } }
    end

    assert_redirected_to conventions_path
  end

  test 'une convention n’est pas créée sans heures conventionnées' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(heures_conventionnees: '') }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée avec zéro heure conventionnée' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(heures_conventionnees: 0) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque l’adhérent en a déjà une pour ce service sur la période' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(
        user_id: users(:weil).id, service_id: services(:informatique).id
      ) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque la date de fin est antérieure à la date de début' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(
        date_fin_prévue: (@today - 1.month).to_s
      ) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque le service n’est pas un service de l’adhérent' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(service_id: services(:informatique).id) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention est supprimée' do
    assert_difference('Convention.count', -1) do
      delete convention_url(@convention)
    end

    assert_redirected_to conventions_path
  end

  test 'les services d’un adhérent sont retournés en JSON' do
    get services_for_adherent_conventions_url(adherent_id: @adherent.id)

    assert_response :success
    assert_includes response.parsed_body.map { |service| service['nom'] }, @service.nom
  end

  test 'aucun service n’est retourné pour un adhérent d’une autre organisation' do
    get services_for_adherent_conventions_url(adherent_id: users(:adherent_marseille).id)

    assert_response :success
    assert_empty response.parsed_body
  end

  test 'un slug de convention inconnu redirige sans planter' do
    get convention_url(id: 'slug-qui-n-existe-pas')

    assert_redirected_to root_path
    assert_equal 'Convention introuvable', flash[:alert]
  end

  private

  def params_valides
    { user_id: @adherent.id, service_id: @service.id, date_début: @today.to_s,
      date_fin_prévue: (@today + 1.year).to_s, heures_conventionnees: 100 }
  end
end
