require "test_helper"

class ConventionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)        # mairie_paris
    @adherent = users(:patrick_adherent_paris)   # a le service service_paris, sans convention
    @service = services(:service_paris)
    @convention = conventions(:convention_paris)
    sign_in @admin
  end

  test "index accessible à un admin" do
    get conventions_url
    assert_response :success
  end

  test "new accessible (avec adhérent prérempli)" do
    get new_convention_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test "create une convention" do
    assert_difference("Convention.count") do
      post conventions_url, params: { convention: {
        user_id: @adherent.id,
        service_id: @service.id,
        date_début: "2026-03-01"
      } }
    end
    assert_redirected_to conventions_path
  end

  test "edit accessible" do
    get edit_convention_url(@convention)
    assert_response :success
  end

  test "update une convention" do
    patch convention_url(@convention), params: { convention: { date_fin_prévue: "2026-12-31" } }
    assert_redirected_to conventions_path
    assert_equal Date.new(2026, 12, 31), @convention.reload.date_fin_prévue
  end

  test "destroy une convention" do
    assert_difference("Convention.count", -1) do
      delete convention_url(@convention)
    end
    assert_redirected_to conventions_path
  end

  test "services_for_adherent renvoie les services disponibles en JSON" do
    get services_for_adherent_conventions_url(adherent_id: @adherent.id)
    assert_response :success
    noms = response.parsed_body.map { |s| s["nom"] }
    assert_includes noms, @service.nom
  end

  test "un agent n'est pas autorisé à voir l'index" do
    sign_in users(:agent_whatsapp)
    get conventions_url
    assert_redirected_to root_path
  end

  # --- Filtres de l'index (convention_paris : service Informatique, début 2026-01-01, fin ouverte, sans document) ---
  # On assertit sur le lien d'édition propre à la ligne du tableau ; le nom de l'adhérent
  # apparaît aussi dans les <option> des menus déroulants et n'est donc pas discriminant.

  test "filtre par service inclut le service correspondant et exclut les autres" do
    row = edit_convention_path(@convention)

    get conventions_url(service_id: services(:informatique).id)
    assert_includes response.body, row

    get conventions_url(service_id: services(:technique).id)
    assert_not_includes response.body, row
  end

  test "filtre active_on inclut une convention active à la date" do
    get conventions_url(active_on: "2026-06-01")
    assert_includes response.body, edit_convention_path(@convention)
  end

  test "filtre active_on exclut une convention pas encore commencée à la date" do
    get conventions_url(active_on: "2025-12-01")
    assert_not_includes response.body, edit_convention_path(@convention)
  end

  test "recherche par nom de document exclut une convention sans document correspondant" do
    get conventions_url(search: "inexistant.pdf")
    assert_not_includes response.body, edit_convention_path(@convention)
  end
end
