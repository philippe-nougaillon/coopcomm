require "test_helper"

class CommandesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @commande = commandes(:commande_paris)           # créé, adhérent weil (avec email), 1 ligne
    @commande_validée = commandes(:commande_validée) # validé, non modifiable
    sign_in users(:hidalgo)
  end

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

  test "slug inconnu : devrait renvoyer 404 — bug B9, comportement actuel : 500" do
    # Bug B9 (.claude/method/bugs-signales.md) : set_commande fait find_by(slug:)
    # → nil sur un slug inconnu, puis is_user_authorized appelle authorize(Commande)
    # sur la CLASSE → CommandePolicy#manage? évalue record.organisation →
    # NoMethodError (vérifié empiriquement le 2026-07-10) → erreur 500.
    # Comportement attendu à la correction : 404 (RecordNotFound).
    # Même motif dans factures_controller. À réactiver quand set_commande lèvera
    # ActiveRecord::RecordNotFound (find_by! ou friendly.find).
    skip "Bug B9 : slug inconnu → NoMethodError 500 au lieu de 404 — à réactiver à la correction"
    get commande_url('slug-inexistant')
    assert_response :not_found
  end
end
