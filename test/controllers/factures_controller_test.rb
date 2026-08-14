# frozen_string_literal: true

require 'test_helper'

class FacturesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @facture = factures(:facture_paris)           # service informatique, état « créé », modifiable
    @facture_validée = factures(:facture_validée) # état « validé », non modifiable
    sign_in users(:hidalgo)
  end

  test 'index : sans paramètre → la page répond' do
    get factures_url

    assert_response :success
  end

  test 'index : un adhérent ne voit que ses factures envoyées, et ses services en sont déduits' do
    envoyée = factures(:facture_secretariat)
    sign_in users(:weil)

    get factures_url

    assert_includes assigns(:factures), envoyée
    assert_not_includes assigns(:factures), @facture
    assert_includes assigns(:services), services(:secretariat)
  end

  test 'index : recherche → seulement les factures correspondantes' do
    get factures_url(search: @facture.ref)

    assert_includes assigns(:factures), @facture
  end

  test 'index : adhérent_ids → seulement les factures de ces adhérents' do
    get factures_url(adhérent_ids: [@facture.adherent_id])

    assert_includes assigns(:factures), @facture
  end

  test 'index : service_ids → seulement les factures de ces services' do
    get factures_url(service_ids: [@facture.service_id])

    assert_includes assigns(:factures), @facture
  end

  test 'index : workflow_state → seulement cet état, quelle que soit la casse' do
    get factures_url(workflow_state: @facture.workflow_state.capitalize)

    assert_includes assigns(:factures), @facture
  end

  test 'index : adherent_id → seulement les factures de cet adhérent' do
    get factures_url(adherent_id: @facture.adherent_id)

    assert_includes assigns(:factures), @facture
  end

  test 'show : une facture de son périmètre → la page répond' do
    get facture_url(@facture)

    assert_response :success
  end

  test 'edit : une facture modifiable → la page répond' do
    get edit_facture_url(@facture)

    assert_response :success
  end

  test 'update : paramètres valides → la facture est modifiée' do
    patch facture_url(@facture), params: { facture: { intitulé: 'Intitulé modifié' } }

    assert_redirected_to facture_url(@facture)
    assert_equal 'Intitulé modifié', @facture.reload.intitulé
  end

  test 'update : intitulé vide → formulaire réaffiché en 422' do
    patch facture_url(@facture), params: { facture: { intitulé: '' } }

    assert_response :unprocessable_content
  end

  test 'update : facture validée donc non modifiable → aucune modification' do
    intitulé_initial = @facture_validée.intitulé

    patch facture_url(@facture_validée), params: { facture: { intitulé: 'Tentative' } }

    assert_response :redirect
    assert_equal intitulé_initial, @facture_validée.reload.intitulé
  end

  # ==================== TESTS CRITIQUES ====================

  test 'critique : update, prix de ligne forgé dans les paramètres → prix inchangé' do
    ligne = facture_lignes(:ligne_facture_paris)
    prix_initial = ligne.prix_ht

    patch facture_url(@facture), params: {
      facture: {
        intitulé: @facture.intitulé,
        facture_lignes_attributes: { '0' => { id: ligne.id, qté: ligne.qté, prix_ht: 999.99 } }
      }
    }

    assert_redirected_to facture_url(@facture)
    assert_equal prix_initial, ligne.reload.prix_ht
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'destroy : une facture de son périmètre → elle est archivée' do
    assert_difference('Facture.kept.count', -1) do
      delete facture_url(@facture)
    end

    assert_redirected_to factures_url
    assert @facture.reload.discarded?
  end

  test 'pdf : une facture de son périmètre → un PDF est rendu' do
    get pdf_facture_url(@facture)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'envoyer : depuis l’état créé → envoyé, et la notification est enfilée' do
    post envoyer_facture_url(@facture)

    assert_redirected_to facture_url(@facture)
    assert @facture.reload.envoyé?
    assert_enqueued_with(job: NotifAdherentFactureEnvoyeeJob,
                         args: [@facture, users(:weil), users(:hidalgo).id])
  end

  test 'envoyer : adhérent sans email → la transition a lieu, aucune notification' do
    users(:weil).update_column(:email, '') # Devise valide la présence de l'email

    assert_no_enqueued_jobs only: NotifAdherentFactureEnvoyeeJob do
      post envoyer_facture_url(@facture)
    end

    assert @facture.reload.envoyé?
  end

  test 'valider : depuis l’état créé → refusé, état inchangé' do
    post valider_facture_url(@facture)

    assert_redirected_to facture_url(@facture)
    assert @facture.reload.créé?
  end

  test 'refuser : depuis l’état envoyé → refusé' do
    @facture.update_columns(workflow_state: Facture::ENVOYE)

    post refuser_facture_url(@facture)

    assert_equal Facture::REFUSE, @facture.reload.workflow_state
  end

  test 'set_facture : un slug inconnu redirige sans planter' do
    get facture_url('slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Facture introuvable', flash[:alert]
  end
end
