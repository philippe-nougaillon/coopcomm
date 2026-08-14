# frozen_string_literal: true

require 'test_helper'

class PrestationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    @prestation = prestations(:nettoyage_bureaux)
    sign_in @admin
  end

  test 'show : une prestation de son organisation → la page répond' do
    get prestation_url(@prestation)

    assert_response :success
  end

  test 'new : sans paramètre → la page répond' do
    get new_prestation_url

    assert_response :success
  end

  test 'edit : une prestation de son organisation → la page répond' do
    get edit_prestation_url(@prestation)

    assert_response :success
  end

  test 'create : paramètres valides → la prestation est créée dans son organisation' do
    assert_difference('Prestation.count') do
      post prestations_url, params: { prestation: { code: 'ABC99', libellé: 'Nouvelle', tarif: 42 } }
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal @admin.organisation, Prestation.order(:created_at).last.organisation
  end

  test 'create : sans code → aucune création et formulaire réaffiché' do
    assert_no_difference -> { Prestation.count } do
      post prestations_url, params: { prestation: { libellé: 'Sans code', tarif: 10 } }
    end

    assert_response :unprocessable_content
  end

  test 'update : paramètres valides → la prestation est modifiée' do
    patch prestation_url(@prestation), params: { prestation: { libellé: 'Modifié' } }

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal 'Modifié', @prestation.reload.libellé
  end

  test 'update : libellé vide → formulaire réaffiché en 422 et prestation inchangée' do
    patch prestation_url(@prestation), params: { prestation: { libellé: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @prestation.reload.libellé
  end

  test 'destroy : une prestation inutilisée → elle est supprimée' do
    inutilisée = prestations(:entretien_espaces_verts)

    assert_difference('Prestation.count', -1) do
      delete prestation_url(inutilisée)
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
  end

  test 'destroy : une prestation utilisée dans une cotation → aucune suppression' do
    assert_no_difference('Prestation.count') do
      delete prestation_url(@prestation)
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
  end

  test 'set_prestation : un slug inconnu redirige sans planter' do
    get prestation_url(id: 'slug-qui-n-existe-pas')

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal 'Prestation introuvable', flash[:alert]
  end
end
