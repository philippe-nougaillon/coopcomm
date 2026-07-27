# frozen_string_literal: true

require 'test_helper'

class ConventionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)        # mairie_paris
    @adherent = users(:patrick_adherent_paris)   # a le service service_paris, sans convention
    @service = services(:service_paris)
    @convention = conventions(:convention_paris)

    # --- On définit des dates dynamiques relatives à AUJOURD'HUI ---
    @today = Date.current
    @start_of_year = @today.beginning_of_year
    @end_of_year = @today.end_of_year

    sign_in @admin
  end

  test 'index accessible à un admin' do
    get conventions_url
    assert_response :success
  end

  test 'new accessible (avec adhérent prérempli)' do
    get new_convention_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test 'create une convention' do
    assert_difference('Convention.count') do
      post conventions_url, params: { convention: {
        user_id: @adherent.id,
        service_id: @service.id,
        date_début: @today.to_s,
        date_fin_prévue: (@today + 1.year).to_s
      } }
    end
    assert_redirected_to conventions_path
  end

  test 'edit accessible' do
    get edit_convention_url(@convention)
    assert_response :success
  end

  test 'update une convention' do
    patch convention_url(@convention), params: { convention: { date_fin_prévue: '2026-12-31' } }
    assert_redirected_to conventions_path
    assert_equal Date.new(2026, 12, 31), @convention.reload.date_fin_prévue
  end

  test 'destroy une convention' do
    assert_difference('Convention.count', -1) do
      delete convention_url(@convention)
    end
    assert_redirected_to conventions_path
  end

  test 'show accessible à un admin et affiche les informations clés' do
    get convention_url(@convention)
    assert_response :success
    assert_select 'h1', text: /Convention/
    assert_match @convention.user.nom_prénom, response.body
    assert_match @convention.service.nom, response.body
  end

  test "le show affiche le journal d'activité (audits) de la convention" do
    # Une modification génère un audit (gem `audited`) ; on vérifie qu'il
    # apparaît dans la section « Activité » (rendue par le partial _audit + prettify).
    @convention.update!(mémo: 'Note de suivi')

    get convention_url(@convention)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Note de suivi/
  end

  test "un agent n'est pas autorisé à voir le show" do
    sign_in users(:agent_whatsapp)
    get convention_url(@convention)
    assert_redirected_to root_path
  end

  test 'services_for_adherent renvoie les services disponibles en JSON' do
    get services_for_adherent_conventions_url(adherent_id: @adherent.id)
    assert_response :success
    noms = response.parsed_body.map { |s| s['nom'] }
    assert_includes noms, @service.nom
  end

  test "un agent n'est pas autorisé à voir l'index" do
    sign_in users(:agent_whatsapp)
    get conventions_url
    assert_redirected_to root_path
  end

  # --- Filtres de l'index (convention_paris : service Informatique, début 2026-01-01, fin ouverte, sans document) ---
  # On assertit sur le lien vers le show propre à la ligne du tableau (seul lien de la ligne
  # depuis que #326 a déplacé les actions dans le show) ; le nom de l'adhérent apparaît aussi
  # dans les <option> des menus déroulants et n'est donc pas discriminant. Le href est cité en
  # entier pour éviter qu'un id préfixe (/conventions/1) ne matche un autre (/conventions/12).

  def convention_row_marker(convention)
    %(href="#{convention_path(convention)}")
  end

  test 'filtre par service inclut le service correspondant et exclut les autres' do
    row = convention_row_marker(@convention)

    get conventions_url(service_id: services(:informatique).id)
    assert_includes response.body, row

    get conventions_url(service_id: services(:technique).id)
    assert_not_includes response.body, row
  end

  test 'filtre active_on inclut une convention active à la date' do
    # On utilise la date de début de l'année en cours, à laquelle on sait que la convention de la fixture est active.
    get conventions_url(active_on: @start_of_year.to_s)
    assert_includes response.body, convention_row_marker(@convention)
  end

  test 'filtre active_on exclut une convention pas encore commencée à la date' do
    # Un año antes del inicio del año actual
    get conventions_url(active_on: (@start_of_year - 1.year).to_s)
    assert_not_includes response.body, convention_row_marker(@convention)
  end

  test 'recherche par nom de document exclut une convention sans document correspondant' do
    get conventions_url(search: 'inexistant.pdf')
    assert_not_includes response.body, convention_row_marker(@convention)
  end

  # --- Créations invalides (les 3 validations métier du model) ---

  test 'create invalide (doublon de convention pour le couple adhérent/service) : aucune création' do
    # weil a déjà convention_paris sur le service informatique
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: users(:weil).id, service_id: services(:informatique).id, date_début: @today.to_s
      } }
    end
    assert_response :unprocessable_content
  end

  test 'create invalide (date de fin antérieure à la date de début) : aucune création' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: @adherent.id, service_id: @service.id,
        date_début: @today.to_s, 
        date_fin_prévue: (@today - 1.month).to_s # Un mes ANTES de empezar (inválido)
      } }
    end
    assert_response :unprocessable_content
  end

  test "create invalide (service n'appartenant pas à l'adhérent) : aucune création" do
    # patrick n'est rattaché qu'au service service_paris, pas à informatique
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: {
        user_id: @adherent.id, service_id: services(:informatique).id, date_début: @today.to_s
      } }
    end
    assert_response :unprocessable_content
  end
end
