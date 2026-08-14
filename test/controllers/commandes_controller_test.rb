# frozen_string_literal: true

require 'test_helper'

class CommandesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @commande = commandes(:commande_paris)           # créé, adhérent weil (avec email), 1 ligne
    @commande_validée = commandes(:commande_validée) # validé, non modifiable
    sign_in users(:hidalgo)
  end

  test 'index : sans paramètre → la page répond' do
    get commandes_url

    assert_response :success
  end

  test 'index : un adhérent ne voit que ses commandes envoyées, et ses services en sont déduits' do
    envoyée = commandes(:commande_secretariat)
    sign_in users(:weil)

    get commandes_url

    assert_includes assigns(:commandes), envoyée
    assert_not_includes assigns(:commandes), @commande
    assert_includes assigns(:services), envoyée.service
  end

  test 'index : recherche → seulement les commandes correspondantes' do
    get commandes_url(search: @commande.ref)

    assert_includes assigns(:commandes), @commande
  end

  test 'index : adhérent_ids → seulement les commandes de ces adhérents' do
    get commandes_url(adhérent_ids: [@commande.adherent_id])

    assert_includes assigns(:commandes), @commande
  end

  test 'index : service_ids → seulement les commandes de ces services' do
    get commandes_url(service_ids: [@commande.service_id])

    assert_includes assigns(:commandes), @commande
  end

  test 'index : workflow_state → seulement cet état, quelle que soit la casse' do
    get commandes_url(workflow_state: @commande.workflow_state.capitalize)

    assert_includes assigns(:commandes), @commande
  end

  test 'index : adherent_id → seulement les commandes de cet adhérent' do
    get commandes_url(adherent_id: @commande.adherent_id)

    assert_includes assigns(:commandes), @commande
  end

  test 'show : une commande de son périmètre → la page répond' do
    get commande_url(@commande)

    assert_response :success
  end

  test 'edit : une commande modifiable → la page répond' do
    get edit_commande_url(@commande)

    assert_response :success
  end

  test 'update : paramètres valides → la commande est modifiée' do
    patch commande_url(@commande), params: { commande: { intitulé: 'Intitulé modifié' } }

    assert_redirected_to commande_url(@commande)
    assert_equal 'Intitulé modifié', @commande.reload.intitulé
  end

  test 'update : intitulé vide → formulaire réaffiché en 422' do
    patch commande_url(@commande), params: { commande: { intitulé: '' } }

    assert_response :unprocessable_content
  end

  test 'update : commande validée donc non modifiable → aucune modification' do
    intitulé_initial = @commande_validée.intitulé

    patch commande_url(@commande_validée), params: { commande: { intitulé: 'Tentative' } }

    assert_response :redirect
    assert_equal intitulé_initial, @commande_validée.reload.intitulé
  end

  # ==================== TESTS CRITIQUES ====================

  test 'update : prix de ligne forgé dans les paramètres → prix inchangé (critique)' do
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

  test 'destroy : une commande de son périmètre → elle est archivée' do
    assert_difference('Commande.kept.count', -1) do
      delete commande_url(@commande)
    end

    assert_redirected_to commandes_url
  end

  test 'pdf : une commande de son périmètre → un PDF est rendu' do
    get pdf_commande_url(@commande)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'envoyer : depuis l’état créé → envoyé, et la notification est enfilée' do
    post envoyer_commande_url(@commande)

    assert_redirected_to commande_path(@commande)
    assert_equal 'envoyé', @commande.reload.workflow_state
    assert_enqueued_with(job: NotifAdherentCommandeEnvoyeeJob,
                         args: [@commande, users(:weil), users(:hidalgo).id])
  end

  test 'envoyer : adhérent sans email → la transition a lieu, aucune notification' do
    users(:weil).update_column(:email, '') # Devise valide la présence de l'email

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  test 'envoyer : depuis un état non envoyable → refusé, aucune notification' do
    @commande.update!(workflow_state: 'envoyé')

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_redirected_to commande_path(@commande)
    assert_equal "Action impossible dans l'état actuel de la commande.", flash[:alert]
    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  test 'valider : depuis l’état envoyé → validé' do
    @commande.update!(workflow_state: 'envoyé')

    post valider_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert @commande.reload.validé?
  end

  test 'valider : depuis l’état créé → refusé, état inchangé' do
    post valider_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert_equal "Action impossible dans l'état actuel de la commande.", flash[:alert]
    assert @commande.reload.créé?
  end

  test 'refuser : depuis l’état envoyé → refusé' do
    @commande.update!(workflow_state: 'envoyé')

    post refuser_commande_url(@commande)

    assert_redirected_to commande_url(@commande)
    assert @commande.reload.refusé?
  end

  test 'create_facture : une commande validée → une facture avec ses lignes' do
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

  test 'create_facture : une commande non validée → aucune facture' do
    assert_no_difference('Facture.count') do
      post create_facture_commande_url(@commande)
    end

    assert_response :redirect
  end

  test 'set_commande : un slug inconnu redirige sans planter' do
    get commande_url('slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Commande introuvable', flash[:alert]
  end
end
