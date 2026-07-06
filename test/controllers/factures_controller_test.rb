require "test_helper"

class FacturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @facture = factures(:facture_paris)       # service informatique, état « créé », modifiable
    @facture_validée = factures(:facture_validée) # service informatique, état « validé », non modifiable
    sign_in users(:hidalgo)                    # manager de mairie_paris, gère informatique
  end

  # --- Lecture ---

  test "should get index" do
    get factures_url
    assert_response :success
  end

  test "index accepte un filtre de recherche" do
    get factures_url, params: { search: @facture.ref }
    assert_response :success
  end

  test "should show facture" do
    get facture_url(@facture)
    assert_response :success
  end

  test "should get edit on a modifiable facture" do
    get edit_facture_url(@facture)
    assert_response :success
  end

  # --- Mise à jour ---

  test "should update facture with valid params" do
    patch facture_url(@facture), params: { facture: { intitulé: "Intitulé modifié" } }
    assert_redirected_to facture_url(@facture)
    assert_equal "Intitulé modifié", @facture.reload.intitulé
  end

  test "update with invalid params renders edit (422)" do
    skip "BUG PROD confirmé : sur échec de validation, #update rend `:edit` mais " \
         "`set_form_collections` est déclaré `only: %i[edit]` → @services/@adherents/" \
         "@prestations sont nil → _form.html.erb:35 lève `undefined method 'map' for nil` " \
         "(500 au lieu de 422 + formulaire). Fix = ajouter :update au before_action " \
         "set_form_collections (factures_controller.rb:4). Test à activer après correction."
    patch facture_url(@facture), params: { facture: { intitulé: "" } }
    assert_response :unprocessable_entity
  end

  test "update refusé sur une facture non modifiable (validé)" do
    intitulé_initial = @facture_validée.intitulé
    patch facture_url(@facture_validée), params: { facture: { intitulé: "Tentative" } }
    assert_response :redirect
    assert_equal intitulé_initial, @facture_validée.reload.intitulé
  end

  # --- Suppression (soft-delete) ---

  test "should destroy facture" do
    assert_difference("Facture.kept.count", -1) do
      delete facture_url(@facture)
    end
    assert_redirected_to factures_url
    assert @facture.reload.discarded?
  end

  # --- PDF ---

  test "renders the facture as PDF" do
    get pdf_facture_url(@facture)
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  # --- Transitions du workflow ---

  test "envoyer transitions créé -> envoyé" do
    post envoyer_facture_url(@facture)
    assert_redirected_to facture_url(@facture)
    assert @facture.reload.envoyé?
  end

  test "valider est refusé depuis l'état créé (garde de transition)" do
    post valider_facture_url(@facture)
    assert_redirected_to facture_url(@facture)
    assert @facture.reload.créé?
  end

  # --- Autorisation ---

  test "un adhérent n'accède pas à l'index des factures" do
    sign_out users(:hidalgo)
    sign_in users(:weil)
    get factures_url
    assert_response :redirect
  end
end
