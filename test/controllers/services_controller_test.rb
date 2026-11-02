# frozen_string_literal: true

require 'test_helper'

class ServicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @service = services(:service_paris)
    sign_in users(:administrateur_paris)
  end

  test 'un service est affiché avec succès' do
    get service_url(@service)

    assert_response :success
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_service_url

    assert_response :success
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_service_url(@service)

    assert_response :success
  end

  test 'un service est créé lorsque les paramètres sont valides' do
    assert_difference('Service.count') do
      post services_url, params: { service: { nom: "Nouveau #{SecureRandom.uuid}",
                                              organisation_id: organisations(:mairie_paris).id } }
    end

    assert_redirected_to admin_parametres_path(tab: 'services')
  end

  # Un service sans nom se retrouve en entrée VIDE dans le sélecteur du formulaire
  # ==================== TESTS CRITIQUES ====================

  # utilisateur : les comptes qu'on y rattache paraissent sans service.
  test "un service sans nom n'est pas créé (critique)" do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: '' } }
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit être rempli'
  end

  # ==================== /TESTS CRITIQUES ====================

  test "un service dont le nom est déjà pris n'est pas créé" do
    assert_no_difference('Service.count') do
      post services_url, params: { service: { nom: services(:technique).nom } }
    end

    assert_response :unprocessable_content
  end

  test 'un service est modifié lorsque les paramètres sont valides' do
    nouveau_nom = "Renommé #{SecureRandom.uuid}"

    patch service_url(@service), params: { service: { nom: nouveau_nom,
                                                      organisation_id: organisations(:mairie_paris).id } }

    assert_redirected_to admin_parametres_path(tab: 'services')
    assert_equal nouveau_nom, @service.reload.nom
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un service dont le nom est vidé garde son nom (critique)' do
    service = services(:technique)

    patch service_url(service), params: { service: { nom: '  ' } }

    assert_response :unprocessable_content
    assert_equal 'Technique', service.reload.nom
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un service renommé avec un nom déjà pris est inchangé' do
    patch service_url(@service), params: { service: { nom: services(:technique).nom } }

    assert_response :unprocessable_content
    assert_not_equal services(:technique).nom, @service.reload.nom
  end

  test 'un service sans rattachement est supprimé' do
    assert_difference('Service.count', -1) do
      delete service_url(services(:menage))
    end

    assert_redirected_to admin_parametres_path(tab: 'services')
  end

  # ==================== TESTS CRITIQUES ====================

  test "un service encore rattaché n'est pas supprimé (critique)" do
    assert_no_difference('Service.count') do
      delete service_url(@service)
    end

    assert_redirected_to root_path
    assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un slug de service inconnu redirige sans planter' do
    get service_url('service-inexistant')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
