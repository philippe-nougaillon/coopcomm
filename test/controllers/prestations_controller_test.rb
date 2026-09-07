# frozen_string_literal: true

require 'test_helper'

class PrestationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    @prestation = prestations(:nettoyage_bureaux)
    sign_in @admin
  end

  test 'une prestation est affichée avec succès' do
    get prestation_url(@prestation)

    assert_response :success
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_prestation_url

    assert_response :success
  end

  test 'le formulaire de création propose « Heure(s) » comme unité' do
    get new_prestation_url

    assert_equal 'Heure(s)', assigns(:prestation).unité
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_prestation_url(@prestation)

    assert_response :success
  end

  test 'le formulaire de modification garde l’unité enregistrée' do
    @prestation.update!(unité: 'Forfait')

    get edit_prestation_url(@prestation)

    assert_equal 'Forfait', assigns(:prestation).unité
  end

  test 'une prestation créée est rattachée à l’organisation de son auteur' do
    assert_difference('Prestation.count') do
      post prestations_url, params: { prestation: { code: 'ABC99', libellé: 'Nouvelle', unité: 'Heure(s)', tarif: 42 } }
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal @admin.organisation, Prestation.order(:created_at).last.organisation
  end

  test 'une prestation sans code n’est pas créée' do
    assert_no_difference -> { Prestation.count } do
      post prestations_url, params: { prestation: { libellé: 'Sans code', unité: 'Heure(s)', tarif: 10 } }
    end

    assert_response :unprocessable_content
  end

  test 'une prestation sans unité n’est pas créée' do
    assert_no_difference -> { Prestation.count } do
      post prestations_url, params: { prestation: { code: 'ABC98', libellé: 'Sans unité', unité: '  ', tarif: 10 } }
    end

    assert_response :unprocessable_content
  end

  test 'une prestation est modifiée avec succès' do
    patch prestation_url(@prestation), params: { prestation: { libellé: 'Modifié' } }

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal 'Modifié', @prestation.reload.libellé
  end

  test 'une prestation dont le libellé est vidé n’est pas modifiée' do
    patch prestation_url(@prestation), params: { prestation: { libellé: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @prestation.reload.libellé
  end

  test 'une prestation inutilisée est supprimée' do
    inutilisée = prestations(:entretien_espaces_verts)

    assert_difference('Prestation.count', -1) do
      delete prestation_url(inutilisée)
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
  end

  test 'une prestation utilisée dans une cotation n’est pas supprimée' do
    assert_no_difference('Prestation.count') do
      delete prestation_url(@prestation)
    end

    assert_redirected_to admin_parametres_path(tab: 'prestations')
  end

  test 'un slug de prestation inconnu redirige sans planter' do
    get prestation_url(id: 'slug-qui-n-existe-pas')

    assert_redirected_to admin_parametres_path(tab: 'prestations')
    assert_equal 'Prestation introuvable', flash[:alert]
  end
end
