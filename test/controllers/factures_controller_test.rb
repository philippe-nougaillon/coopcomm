# frozen_string_literal: true

require 'test_helper'

class FacturesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @facture = factures(:facture_paris)           # service informatique, état « créé », modifiable
    @facture_validée = factures(:facture_validée) # état « validé », non modifiable
    sign_in users(:hidalgo)
  end

  test 'la liste des factures est affichée avec succès' do
    get factures_url

    assert_response :success
  end

  test 'la recherche dans la liste ne retourne que les factures correspondantes' do
    get factures_url(search: @facture.ref)

    assert_includes assigns(:factures), @facture
  end

  test 'la liste filtrée par adhérents ne retourne que les factures de ces adhérents' do
    get factures_url(adhérent_ids: [@facture.adherent_id])

    assert_includes assigns(:factures), @facture
  end

  test 'la liste filtrée par services ne retourne que les factures de ces services' do
    get factures_url(service_ids: [@facture.service_id])

    assert_includes assigns(:factures), @facture
  end

  test 'la liste filtrée par état ne retourne que les factures de cet état, quelle que soit la casse' do
    get factures_url(workflow_state: @facture.workflow_state.humanize)

    assert_includes assigns(:factures), @facture
  end

  test 'la liste filtrée par le paramètre adherent_id ne retourne que les factures de cet adhérent' do
    get factures_url(adherent_id: @facture.adherent_id)

    assert_includes assigns(:factures), @facture
  end

  test 'une facture est affichée avec succès' do
    get facture_url(@facture)

    assert_response :success
  end

  test 'le formulaire de modification d’une facture modifiable est affiché avec succès' do
    get edit_facture_url(@facture)

    assert_response :success
  end

  test 'une facture est modifiée avec succès' do
    patch facture_url(@facture), params: { facture: { intitulé: 'Intitulé modifié' } }

    assert_redirected_to facture_url(@facture)
    assert_equal 'Intitulé modifié', @facture.reload.intitulé
  end

  test 'une facture dont l’intitulé est vidé n’est pas modifiée' do
    patch facture_url(@facture), params: { facture: { intitulé: '' } }

    assert_response :unprocessable_content
  end

  test 'une facture validée n’est pas modifiée' do
    intitulé_initial = @facture_validée.intitulé

    patch facture_url(@facture_validée), params: { facture: { intitulé: 'Tentative' } }

    assert_response :redirect
    assert_equal intitulé_initial, @facture_validée.reload.intitulé
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un prix de ligne forgé dans les paramètres est ignoré (critique)' do
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

  test 'une facture est archivée lorsqu’elle est supprimée' do
    assert_difference('Facture.kept.count', -1) do
      delete facture_url(@facture)
    end

    assert_redirected_to factures_url
    assert @facture.reload.discarded?
  end

  test 'une facture est rendue en PDF' do
    get pdf_facture_url(@facture)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'une facture à l’état créé peut être envoyée et la notification de l’adhérent est enfilée' do
    post envoyer_facture_url(@facture)

    assert_redirected_to facture_url(@facture)
    assert @facture.reload.envoyé?
    assert_enqueued_with(job: NotifAdherentFactureEnvoyeeJob,
                         args: [@facture, users(:weil), users(:hidalgo).id])
  end

  test 'une facture est envoyée sans notification lorsque l’adhérent n’a pas d’email' do
    users(:weil).update_column(:email, '') # Devise valide la présence de l'email

    assert_no_enqueued_jobs only: NotifAdherentFactureEnvoyeeJob do
      post envoyer_facture_url(@facture)
    end

    assert @facture.reload.envoyé?
  end

  test 'une facture à l’état créé ne peut pas être validée' do
    post valider_facture_url(@facture)

    assert_redirected_to facture_url(@facture)
    assert @facture.reload.créé?
  end

  test 'une facture à l’état envoyé peut être refusée' do
    @facture.update_columns(workflow_state: Facture::ENVOYE)

    post refuser_facture_url(@facture)

    assert_equal Facture::REFUSE, @facture.reload.workflow_state
  end

  test 'un slug de facture inconnu redirige sans planter' do
    get facture_url('slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Facture introuvable', flash[:alert]
  end
end
