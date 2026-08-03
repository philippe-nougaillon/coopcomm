# frozen_string_literal: true

require 'test_helper'

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tool = tools(:tondeuse)
    sign_in users(:hidalgo)
  end

  # ==========================================================================
  # ==================== TESTS CRITIQUES =====================================
  # ==========================================================================

  test 'un outil utilisé par une intervention est quand même supprimé' do
    # ÉPINGLAGE d'un BUG SIGNALÉ (B19) : la vue masque bien le bouton depuis #412,
    # mais tools#destroy ne garde rien — une requête directe passe et emporte
    # les tool_interventions en cascade. À inverser à la correction.
    assert_predicate @tool.interventions, :any?

    delete tool_url(@tool)

    assert_not Tool.exists?(@tool.id)
  end

  test "l'index ne montre pas le matériel d'une autre organisation" do
    get tools_url

    assert_not_includes assigns(:tools), tools(:camion)
  end

  # ==========================================================================
  # A. Fenêtre de dates de l'index et du show
  # ==========================================================================

  test "l'index affiche par défaut la semaine en cours" do
    get tools_url

    assert_equal Date.today.beginning_of_week, assigns(:date)
    assert_equal Date.today.end_of_week, assigns(:date_fin)
  end

  test "l'index cadre la semaine de la date demandée" do
    jeudi = Date.new(2026, 6, 4)

    get tools_url(date: jeudi.to_s)

    assert_equal jeudi.beginning_of_week, assigns(:date)
    assert_equal jeudi.end_of_week, assigns(:date_fin)
  end

  test "l'index retombe sur la semaine en cours quand la date est illisible" do
    get tools_url(date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_week, assigns(:date)
  end

  test 'le show cadre le mois de la date demandée et la grille qui lentoure' do
    quinze = Date.new(2026, 6, 15)

    get tool_url(@tool, date: quinze.to_s)

    assert_equal quinze.beginning_of_month, assigns(:date)
    assert_equal quinze.end_of_month, assigns(:date_fin)
    assert_equal quinze.beginning_of_month.beginning_of_week, assigns(:date_inicio_grid)
    assert_equal quinze.end_of_month.end_of_week, assigns(:date_fin_grid)
  end

  test 'le show retombe sur le mois en cours quand la date est illisible' do
    get tool_url(@tool, date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_month, assigns(:date)
  end

  # Les flèches du calendrier émettent start_date sans effacer un date= plus
  # ancien : la grille d'états doit suivre le mois réellement affiché.
  test 'le show suit la navigation par start_date du calendrier' do
    get tool_url(@tool, date: '2026-01-05', start_date: '2026-06-15')

    assert_equal Date.new(2026, 6, 1), assigns(:date)
    assert_equal Date.new(2026, 6, 1).beginning_of_week, assigns(:date_inicio_grid)
  end

  # ==========================================================================
  # A bis. Cases de disponibilité du show (mêmes états que l'index)
  # ==========================================================================

  test 'le calendrier du show propose de réserver une journée libre' do
    outil = tools(:cisaille)

    get tool_url(outil, date: '2026-06-15')

    assert_select 'a[href=?]', reserve_tool_mouvements_path(
      tool_id: outil.id, date: Date.new(2026, 6, 15), user_id: users(:hidalgo).id
    )
  end

  test 'le calendrier du show propose de libérer ma propre réservation' do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:hidalgo), état: :réservé,
                      date: Time.zone.parse('2026-06-15 09:00'))

    get tool_url(outil, date: '2026-06-15')

    assert_select 'a[href=?]', libere_tool_mouvements_path(
      tool_id: outil.id, date: Date.new(2026, 6, 15), user_id: users(:hidalgo).id
    )
  end

  test 'le calendrier du show marque en panne dès le jour de la déclaration' do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:hidalgo), état: :panne,
                      date: Time.zone.parse('2026-06-15 09:00'))

    get tool_url(outil, date: '2026-06-15')

    assert_select 'span[title=?]', 'En panne'
    assert_select 'a[href=?]', reserve_tool_mouvements_path(
      tool_id: outil.id, date: Date.new(2026, 6, 15), user_id: users(:hidalgo).id
    ), count: 0
    assert_select 'a[href=?]', libere_tool_mouvements_path(
      tool_id: outil.id, date: Date.new(2026, 6, 15), user_id: users(:hidalgo).id
    ), count: 0
  end

  # ==========================================================================
  # A ter. Libérer la réservation d'un autre (manager / admin)
  # ==========================================================================

  test "l'index propose à un manager de libérer la réservation d'un autre" do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:bond), état: :réservé, date: Date.today)

    get tools_url

    assert_select 'a[href=?]', libere_tool_mouvements_path(
      tool_id: outil.id, date: Date.today, user_id: users(:bond).id
    )
  end

  test "le show propose à un manager de libérer la réservation d'un autre" do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:bond), état: :réservé,
                      date: Time.zone.parse('2026-06-15 09:00'))

    get tool_url(outil, date: '2026-06-15')

    assert_select 'a[href=?]', libere_tool_mouvements_path(
      tool_id: outil.id, date: Date.new(2026, 6, 15), user_id: users(:bond).id
    )
  end

  test "un agent ne se voit pas proposer de libérer la réservation d'un autre" do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:bond), état: :réservé, date: Date.today)
    sign_in users(:martin_technique_paris)

    get tools_url

    assert_select 'a[href=?]', libere_tool_mouvements_path(
      tool_id: outil.id, date: Date.today, user_id: users(:bond).id
    ), count: 0
    assert_select 'span[title=?]', "Réservé par qqn d'autre"
  end

  # La fin de panne d'un clic sur la case a été abandonnée avec la bascule du
  # show sur les cases de l'index : elle passe par « Gestion panne ».
  test 'une case en panne du show ne déclare plus la fin de panne' do
    outil = tools(:cisaille)
    Mouvement.create!(tool: outil, user: users(:hidalgo), état: :panne,
                      date: Time.zone.parse('2026-06-15 09:00'))

    get tool_url(outil, date: '2026-06-15')

    assert_not_includes response.body, 'fin_panne'
    assert_select 'a[href=?]', new_mouvement_path(tool_id: outil.id)
  end

  # ==========================================================================
  # B. Recherche et filtres de l'index
  # ==========================================================================

  test "la recherche de l'index restreint la liste" do
    get tools_url(search: 'Rateau')

    assert_includes assigns(:tools), tools(:rateau)
    assert_not_includes assigns(:tools), tools(:cisaille)
  end

  test "le filtre par type de l'index restreint la liste" do
    get tools_url(type: @tool.icon_name)

    assert_includes assigns(:tools), @tool
    assert_not_includes assigns(:tools), tools(:rateau)
  end

  test 'un slug doutil inconnu redirige sans planter' do
    get tool_url(id: 'slug-inexistant')

    assert_redirected_to root_path
  end

  test 'should get index' do
    # Appel du service MeteoConceptConnexion limité pour éviter l'appel de l'API MeteoConcept dans les tests
    MeteoConceptConnexion.stub :call, nil do
      get tools_url
    end

    MeteoConceptConnexion.stub :call, { forecast: [] } do
      get tools_url
    end

    assert_response :success
  end

  test 'should get new' do
    get new_tool_url
    assert_response :success
  end

  test 'should create tool' do
    assert_difference('Tool.count') do
      post tools_url, params: {
        tool: {
          name: generate_name,
          description: @tool.description,
          organisation_id: @tool.organisation_id,
          icon_name: @tool.icon_name,
          modèle: @tool.modèle,
          marque: @tool.marque,
          slug: @tool.slug
        }
      }
    end

    assert_redirected_to tool_url(Tool.last)
  end

  test 'should show tool' do
    get tool_url(@tool)
    assert_response :success
  end

  test 'should get edit' do
    get edit_tool_url(@tool)
    assert_response :success
  end

  test 'should update tool' do
    patch tool_url(@tool), params: {
      tool: {
        name: generate_name,
        description: @tool.description,
        icon_name: @tool.icon_name,
        modèle: @tool.modèle,
        marque: @tool.marque
      }
    }
    assert_redirected_to tool_url(@tool)
  end

  test 'should destroy tool' do
    assert_difference('Tool.count', -1) do
      delete tool_url(@tool)
    end

    assert_redirected_to tools_url
  end

  def generate_name
    "#{@tool.name}-#{SecureRandom.hex(4)}"
  end

  # --- create / update : branches d'échec ---

  test 'create invalide réaffiche le formulaire en 422' do
    assert_no_difference('Tool.count') do
      post tools_url, params: { tool: { name: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'create invalide en JSON renvoie les erreurs' do
    post tools_url, params: { tool: { name: '' } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end

  test 'update invalide réaffiche le formulaire en 422' do
    patch tool_url(@tool), params: { tool: { name: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @tool.reload.name
  end

  test 'update invalide en JSON renvoie les erreurs' do
    patch tool_url(@tool), params: { tool: { name: '' } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end
end
