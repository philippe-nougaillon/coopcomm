require "test_helper"

class CommandesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @commande = commandes(:commande_paris) # créé, adhérent weil (avec email)
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
end
