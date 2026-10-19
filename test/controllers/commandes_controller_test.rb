# frozen_string_literal: true

require 'test_helper'

class CommandesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @commande = commandes(:commande_paris)           # créé, adhérent weil (avec email), 1 ligne
    @commande_validée = commandes(:commande_validée) # validé, non modifiable
    sign_in users(:hidalgo)
  end

  test 'la liste des commandes est affichée avec succès' do
    get commandes_url

    assert_response :success
  end

  test 'la recherche dans la liste ne retourne que les commandes correspondantes' do
    get commandes_url(search: @commande.ref)

    assert_includes assigns(:commandes), @commande
  end

  test 'la liste filtrée par adhérents ne retourne que les commandes de ces adhérents' do
    get commandes_url(adhérent_ids: [@commande.adherent_id])

    assert_includes assigns(:commandes), @commande
  end

  test 'la liste filtrée par services ne retourne que les commandes de ces services' do
    get commandes_url(service_ids: [@commande.service_id])

    assert_includes assigns(:commandes), @commande
  end

  test 'la liste filtrée par état ne retourne que les commandes de cet état, quelle que soit la casse' do
    get commandes_url(workflow_state: @commande.workflow_state.humanize)

    assert_includes assigns(:commandes), @commande
  end

  test 'la liste filtrée par le paramètre adherent_id ne retourne que les commandes de cet adhérent' do
    get commandes_url(adherent_id: @commande.adherent_id)

    assert_includes assigns(:commandes), @commande
  end

  test 'une commande est affichée avec succès' do
    get commande_url(@commande)

    assert_response :success
  end

  test 'le formulaire de modification d’une commande modifiable est affiché avec succès' do
    get edit_commande_url(@commande)

    assert_response :success
  end

  test 'une commande est modifiée avec succès' do
    patch commande_url(@commande), params: { commande: { intitulé: 'Intitulé modifié' } }

    assert_redirected_to commande_url(@commande)
    assert_equal 'Intitulé modifié', @commande.reload.intitulé
  end

  test 'une commande dont l’intitulé est vidé n’est pas modifiée' do
    patch commande_url(@commande), params: { commande: { intitulé: '' } }

    assert_response :unprocessable_content
  end

  test 'une commande validée n’est pas modifiée' do
    intitulé_initial = @commande_validée.intitulé

    patch commande_url(@commande_validée), params: { commande: { intitulé: 'Tentative' } }

    assert_response :redirect
    assert_equal intitulé_initial, @commande_validée.reload.intitulé
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un prix de ligne forgé dans les paramètres est ignoré (critique)' do
    ligne = commande_lignes(:ligne_commande_paris)
    prix_initial = ligne.prix_ht

    patch commande_url(@commande), params: {
      commande: {
        intitulé: @commande.intitulé,
        commande_lignes_attributes: { '0' => { id: ligne.id, qté: ligne.qté, prix_ht: 999.99 } }
      }
    }

    assert_redirected_to commande_url(@commande)
    assert_equal prix_initial, ligne.reload.prix_ht
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une commande est archivée lorsqu’elle est supprimée' do
    assert_difference('Commande.kept.count', -1) do
      delete commande_url(@commande)
    end

    assert_redirected_to commandes_url
  end

  test 'une commande est rendue en PDF' do
    get pdf_commande_url(@commande)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'une commande à l’état créé peut être envoyée et la notification de l’adhérent est enfilée' do
    post envoyer_commande_url(@commande)

    assert_redirected_to commande_path(@commande)
    assert_equal 'envoyé', @commande.reload.workflow_state
    assert_enqueued_with(job: NotifAdherentCommandeEnvoyeeJob,
                         args: [@commande, users(:weil), users(:hidalgo).id])
  end

  test 'une commande est envoyée sans notification lorsque l’adhérent n’a pas d’email' do
    users(:weil).update_column(:email, '') # Devise valide la présence de l'email

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  test 'une commande à l’état envoyé ne peut pas être envoyée de nouveau et aucune notification n’est enfilée' do
    @commande.update!(workflow_state: 'envoyé')

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_redirected_to commande_path(@commande)
    assert_equal "Action impossible dans l'état actuel de la commande.", flash[:alert]
    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  test 'une commande à l’état envoyé peut être validée' do
    @commande.update!(workflow_state: 'envoyé')

    post valider_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert @commande.reload.validé?
  end

  test 'une commande à l’état créé ne peut pas être validée' do
    post valider_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert_equal "Action impossible dans l'état actuel de la commande.", flash[:alert]
    assert @commande.reload.créé?
  end

  test 'une commande à l’état envoyé peut être refusée' do
    @commande.update!(workflow_state: 'envoyé')

    post refuser_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert @commande.reload.refusé?
  end

  test 'une facture est créée avec ses lignes depuis une commande validée' do
    @commande.update!(workflow_state: 'validé')

    assert_difference('Facture.count', 1) do
      post create_facture_commande_url(@commande)
    end

    facture = Facture.order(:created_at).last
    assert_redirected_to facture_url(facture)
    assert_equal @commande.intitulé, facture.intitulé
    assert_equal @commande.adherent_id, facture.adherent_id
    assert_equal 1, facture.facture_lignes.count
    assert_equal prestations(:nettoyage_bureaux), facture.facture_lignes.first.prestation
    assert_equal 3, facture.facture_lignes.first.qté
  end

  test 'aucune facture n’est créée depuis une commande non validée' do
    assert_no_difference('Facture.count') do
      post create_facture_commande_url(@commande)
    end

    assert_response :redirect
  end

  test 'un slug de commande inconnu redirige sans planter' do
    get commande_url('slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Commande introuvable', flash[:alert]
  end
end
