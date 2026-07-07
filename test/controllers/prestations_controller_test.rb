# frozen_string_literal: true

require 'test_helper'

class PrestationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    @prestation = prestations(:nettoyage_bureaux)
    sign_in @admin
  end

  test 'new' do
    get new_prestation_url
    assert_response :success
  end

  test "create dans l'organisation courante" do
    assert_difference('Prestation.count') do
      post prestations_url, params: { prestation: { code: 'ABC99', libellé: 'Nouvelle', tarif: 42 } }
    end
    assert_redirected_to admin_parametres_path
    assert_equal @admin.organisation, Prestation.order(:created_at).last.organisation
  end

  test 'edit' do
    get edit_prestation_url(@prestation)
    assert_response :success
  end

  test 'update' do
    patch prestation_url(@prestation), params: { prestation: { libellé: 'Modifié' } }
    assert_redirected_to admin_parametres_path
    assert_equal 'Modifié', @prestation.reload.libellé
  end

  test 'destroy refusé si la prestation est utilisée dans une cotation' do
    # nettoyage_bureaux est utilisée par la ligne de cotation_paris
    assert_no_difference('Prestation.count') do
      delete prestation_url(@prestation)
    end
    assert_redirected_to admin_parametres_path
  end

  test "destroy d'une prestation inutilisée" do
    presta = prestations(:entretien_espaces_verts)
    assert_difference('Prestation.count', -1) do
      delete prestation_url(presta)
    end
    assert_redirected_to admin_parametres_path
  end

  test 'un manager ne peut pas gérer le catalogue' do
    sign_in users(:manager_paris)
    get new_prestation_url
    assert_redirected_to root_path
  end

  test 'un adhérent ne peut pas gérer le catalogue' do
    sign_in users(:weil)
    get new_prestation_url
    assert_redirected_to root_path
  end

  # --- Création invalide ---

  test 'create invalide (sans code) : aucune prestation créée et formulaire re-rendu' do
    assert_no_difference -> { Prestation.count } do
      post prestations_url, params: { prestation: { libellé: 'Sans code', tarif: 10 } }
    end
    assert_response :unprocessable_entity
  end
end
