require "test_helper"

class CommandesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @commande = commandes(:commande_paris)           # créé, adhérent weil (avec email), 1 ligne
    @commande_validée = commandes(:commande_validée) # validé, non modifiable
    sign_in users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'une ligne ne se manipule jamais par la requête, et un lien mort ne
  # fait jamais un 500.

  # Test critique — le prix d'une ligne ne peut pas être forcé via les
  # paramètres (miroir du test cotation ; scénario compte volé/malveillant).
  test "critique : le prix d'une ligne de commande ne peut pas être forcé via les paramètres" do
    ligne = commande_lignes(:ligne_commande_paris)
    prix_initial = ligne.prix_ht

    patch commande_url(@commande), params: {
      commande: {
        intitulé: @commande.intitulé,
        commande_lignes_attributes: { '0' => { id: ligne.id, qté: ligne.qté, prix_ht: 999.99 } }
      }
    }

    assert_redirected_to commande_url(@commande)
    assert_equal prix_initial, ligne.reload.prix_ht, 'le prix forgé doit être ignoré'
  end

  # Test critique — un lien mort (vieux mail, slug régénéré) est un cas du quotidien :
  # redirection propre, jamais un 500.
  test "critique : slug inconnu → redirection avec alerte (ex-bug B9)" do
    get commande_url('slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Commande introuvable', flash[:alert]
  end

  # ==================== /TESTS CRITIQUES ====================

  test "should get index" do
    get commandes_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_commande_url
  #   assert_response :success
  # end

  # test "should create commande" do
  #   assert_difference("Commande.count") do
  #     post commandes_url, params: { commande: {} }
  #   end
  #
  #   assert_redirected_to commande_url(Commande.last)
  # end

  test "should show commande" do
    get commande_url(@commande)
    assert_response :success
  end

  # test "should get edit" do
  #   get edit_commande_url(@commande)
  #   assert_response :success
  # end
  #
  # test "should update commande" do
  #   patch commande_url(@commande), params: { commande: {} }
  #   assert_redirected_to commande_url(@commande)
  # end

  test "should destroy commande" do
    assert_difference("Commande.kept.count", -1) do
      delete commande_url(@commande)
    end

    assert_redirected_to commandes_url
  end

  # --- Envoi à l'adhérent (envoyer) ---

  test "envoyer : créé -> envoyé et enqueue la notification de l'adhérent avec les bons arguments" do
    post envoyer_commande_url(@commande)

    assert_redirected_to commande_path(@commande)
    assert_equal 'envoyé', @commande.reload.workflow_state
    assert_enqueued_with(job: NotifAdherentCommandeEnvoyeeJob,
                         args: [@commande, users(:weil), users(:hidalgo).id])
  end

  test "envoyer : adhérent sans email -> la transition a lieu mais aucune notification n'est enqueue" do
    users(:weil).update_column(:email, '') # bypass : Devise valide la présence de l'email

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  test "envoyer : impossible depuis un état non envoyable, aucune notification" do
    # commande_secretariat (déjà « envoyé ») est hors du périmètre de hidalgo :
    # on amène une commande de SON périmètre dans un état non envoyable.
    @commande.update!(workflow_state: 'envoyé')

    assert_no_enqueued_jobs only: NotifAdherentCommandeEnvoyeeJob do
      post envoyer_commande_url(@commande)
    end

    assert_redirected_to commande_path(@commande)
    assert_equal 'Action impossible dans l\'état actuel de la commande.', flash[:alert]
    assert_equal 'envoyé', @commande.reload.workflow_state
  end

  # --- Transitions valider / refuser (miroir factures_controller_test) ---

  test "valider : envoyé -> validé" do
    @commande.update!(workflow_state: 'envoyé')
    post valider_commande_url(@commande)
    assert_redirected_to commande_url(@commande)
    assert @commande.reload.validé?
  end

  test "refuser : envoyé -> refusé" do
    @commande.update!(workflow_state: 'envoyé')
    post refuser_commande_url(@commande)
    assert_redirected_to commande_url(@commande)
    assert @commande.reload.refusé?
  end

  test "valider est refusé depuis l'état créé (garde de transition)" do
    post valider_commande_url(@commande)
    assert_redirected_to commande_url(@commande)
    assert_equal 'Action impossible dans l\'état actuel de la commande.', flash[:alert]
    assert @commande.reload.créé?
  end

  # --- Lecture / recherche ---

  test "index accepte un filtre de recherche" do
    get commandes_url, params: { search: @commande.ref }
    assert_response :success
  end

  test "should get edit on a modifiable commande" do
    get edit_commande_url(@commande)
    assert_response :success
  end

  # --- Mise à jour ---

  test "should update commande with valid params" do
    patch commande_url(@commande), params: { commande: { intitulé: "Intitulé modifié" } }
    assert_redirected_to commande_url(@commande)
    assert_equal "Intitulé modifié", @commande.reload.intitulé
  end

  test "update with invalid params renders edit (422)" do
    patch commande_url(@commande), params: { commande: { intitulé: "" } }
    assert_response :unprocessable_content
  end

  test "update refusé sur une commande non modifiable (validé)" do
    intitulé_initial = @commande_validée.intitulé
    patch commande_url(@commande_validée), params: { commande: { intitulé: "Tentative" } }
    assert_response :redirect
    assert_equal intitulé_initial, @commande_validée.reload.intitulé
  end

  # --- PDF ---

  test "renders the commande as PDF" do
    get pdf_commande_url(@commande)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  # --- create_facture (spécifique aux commandes) ---

  test "create_facture : une commande validée engendre une facture avec ses lignes" do
    @commande.update!(workflow_state: 'validé')

    assert_difference("Facture.count", 1) do
      post create_facture_commande_url(@commande)
    end

    facture = Facture.order(:created_at).last
    assert_redirected_to facture_url(facture)
    assert_equal @commande.intitulé, facture.intitulé
    assert_equal @commande.adherent_id, facture.adherent_id
    assert_equal 1, facture.facture_lignes.count
    ligne = facture.facture_lignes.first
    assert_equal prestations(:nettoyage_bureaux), ligne.prestation
    assert_equal 3, ligne.qté
  end

  test "create_facture refusé sur une commande non validée (policy)" do
    assert_no_difference("Facture.count") do
      post create_facture_commande_url(@commande) # état « créé »
    end
    assert_response :redirect
  end

  # --- Robustesse ---
  # (le test « slug inconnu » vit dans les TESTS CRITIQUES en tête de fichier)

  # --- index : périmètre de l'adhérent et filtres ---

  # L'adhérent ne voit pas les brouillons (état « créé ») ; ses services sont
  # déduits des commandes visibles et non de ses rattachements.
  test 'index d\'un adhérent liste ses commandes envoyées et déduit ses services' do
    envoyée = commandes(:commande_secretariat)
    sign_in users(:weil)

    get commandes_url

    assert_response :success
    assert_includes assigns(:commandes), envoyée
    assert_not_includes assigns(:commandes), @commande
    assert_includes assigns(:services), envoyée.service
  end

  test 'index filtre sur les adhérents sélectionnés' do
    get commandes_url(adhérent_ids: [@commande.adherent_id])

    assert_response :success
    assert_includes assigns(:commandes), @commande
  end

  test 'index filtre sur les services sélectionnés' do
    get commandes_url(service_ids: [@commande.service_id])

    assert_response :success
    assert_includes assigns(:commandes), @commande
  end

  test 'index filtre sur le statut quelle que soit la casse' do
    get commandes_url(workflow_state: @commande.workflow_state.capitalize)

    assert_response :success
    assert_includes assigns(:commandes), @commande
  end

  # --- refuser ---

  test 'refuser une commande envoyée la passe à refusé' do
    @commande.update_columns(workflow_state: Commande::ENVOYE)

    post refuser_commande_url(@commande)

    assert_equal Commande::REFUSE, @commande.reload.workflow_state
  end
end
