require "test_helper"

class CotationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    @adherent = users(:weil)
    @service = services(:informatique)
    @prestation = prestations(:nettoyage_bureaux)      # tarif 25.50
    sign_in @admin
  end

  test "index accessible à un admin" do
    get cotations_url
    assert_response :success
  end

  test "new accessible avec adhérent prérempli" do
    get new_cotation_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test "create : le total est calculé à partir du tarif des prestations et une ref est générée" do
    presta2 = prestations(:entretien_espaces_verts)    # tarif 30.00

    assert_difference -> { Cotation.count } => 1, -> { CotationLigne.count } => 2 do
      post cotations_url, params: { cotation: {
        adherent_id: @adherent.id,
        service_id: @service.id,
        intitulé: "Devis test contrôleur",
        cotation_lignes_attributes: {
          "0" => { prestation_id: @prestation.id, qté: 3 },   # 25.50 × 3 = 76.50
          "1" => { prestation_id: presta2.id, qté: 2 }        # 30.00 × 2 = 60.00
        }
      } }
    end

    cotation = Cotation.order(:created_at).last
    assert_redirected_to cotation_path(cotation)
    assert_equal 136.5, cotation.total_ht.to_f
    assert_equal "créé", cotation.workflow_state
    assert_match(/\A#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test "le prix d'une ligne ne peut pas être forcé via les paramètres" do
    post cotations_url, params: { cotation: {
      adherent_id: @adherent.id, service_id: @service.id, intitulé: "Devis",
      cotation_lignes_attributes: { "0" => { prestation_id: @prestation.id, qté: 1, prix_ht: 1 } }
    } }
    ligne = Cotation.order(:created_at).last.cotation_lignes.first
    assert_equal @prestation.tarif, ligne.prix_ht
  end

  # --- Workflow ---

  test "envoyer : créé -> envoyé" do
    cotation = cotations(:cotation_paris) # créé
    get envoyer_cotation_url(cotation)
    assert_redirected_to cotation_path(cotation)
    assert_equal "envoyé", cotation.reload.workflow_state
  end

  test "valider : envoyé -> validé" do
    cotation = cotations(:cotation_secretariat) # envoyé
    get valider_cotation_url(cotation)
    assert_equal "validé", cotation.reload.workflow_state
  end

  test "refuser : envoyé -> refusé" do
    cotation = cotations(:cotation_secretariat) # envoyé
    get refuser_cotation_url(cotation)
    assert_equal "refusé", cotation.reload.workflow_state
  end

  test "valider est sans effet sur une cotation en créé (transition impossible)" do
    cotation = cotations(:cotation_paris) # créé
    get valider_cotation_url(cotation)
    assert_equal "créé", cotation.reload.workflow_state
  end

  test "show et génération du PDF" do
    cotation = cotations(:cotation_paris)
    get cotation_url(cotation)
    assert_response :success

    # L'URL se termine par le nom de fichier (et non "pdf.pdf")
    path = pdf_cotation_path(cotation, filename: cotation.pdf_filename)
    assert path.end_with?("/Cotation-#{cotation.ref}.pdf"), path

    get path
    assert_response :success
    assert_equal "application/pdf", response.media_type
  end

  test "destroy effectue un soft delete" do
    cotation = cotations(:cotation_paris)
    assert_no_difference -> { Cotation.count } do
      delete cotation_url(cotation)
    end
    assert cotation.reload.discarded?
    assert_redirected_to cotations_path
  end

  test "un agent n'est pas autorisé à voir l'index" do
    sign_in users(:agent_whatsapp)
    get cotations_url
    assert_redirected_to root_path
  end
end
