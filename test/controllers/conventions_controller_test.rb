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
end
