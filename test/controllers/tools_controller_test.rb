# frozen_string_literal: true

require 'test_helper'

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tool = tools(:tondeuse)
    sign_in users(:hidalgo)
  end

  test 'index : sans paramètre → la page répond' do
    get tools_url

    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test "index : le matériel d'une autre organisation n'apparaît pas (critique)" do
    get tools_url

    assert_not_includes assigns(:tools), tools(:camion)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'index : sans date → la semaine en cours' do
    get tools_url

    assert_equal Date.today.beginning_of_week, assigns(:date)
    assert_equal Date.today.end_of_week, assigns(:date_fin)
  end

  test 'index : une date → la semaine qui la contient' do
    jeudi = Date.new(2026, 6, 4)

    get tools_url(date: jeudi.to_s)

    assert_equal jeudi.beginning_of_week, assigns(:date)
    assert_equal jeudi.end_of_week, assigns(:date_fin)
  end

  test 'index : une date illisible → retour à la semaine en cours' do
    get tools_url(date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_week, assigns(:date)
  end

  test 'index : recherche → seulement le matériel correspondant' do
    get tools_url(search: 'Rateau')

    assert_includes assigns(:tools), tools(:rateau)
    assert_not_includes assigns(:tools), tools(:cisaille)
  end

  # À réactiver avec le filtre « Type », commenté dans la vue et dans le contrôleur.
  # test 'index : filtre par type → seulement le matériel de ce type' do
  #   get tools_url(type: @tool.icon_name)
  #
  #   assert_includes assigns(:tools), @tool
  #   assert_not_includes assigns(:tools), tools(:rateau)
  # end

  test 'show : un outil de son organisation → la page répond' do
    get tool_url(@tool)

    assert_response :success
  end

  test 'show : une date → le mois qui la contient et la grille qui l’entoure' do
    quinze = Date.new(2026, 6, 15)

    get tool_url(@tool, date: quinze.to_s)

    assert_equal quinze.beginning_of_month, assigns(:date)
    assert_equal quinze.end_of_month, assigns(:date_fin)
    assert_equal quinze.beginning_of_month.beginning_of_week, assigns(:date_inicio_grid)
    assert_equal quinze.end_of_month.end_of_week, assigns(:date_fin_grid)
  end

  test 'show : une date illisible → retour au mois en cours' do
    get tool_url(@tool, date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_month, assigns(:date)
  end

  # Les flèches du calendrier émettent start_date sans effacer un date= plus ancien :
  # la grille d'états doit suivre le mois réellement affiché.
  test 'show : start_date prime sur un date= plus ancien' do
    get tool_url(@tool, date: '2026-01-05', start_date: '2026-06-15')

    assert_equal Date.new(2026, 6, 1), assigns(:date)
    assert_equal Date.new(2026, 6, 1).beginning_of_week, assigns(:date_inicio_grid)
  end

  test 'show : un manager reçoit l’historique des modifications de l’outil' do
    @tool.update!(name: 'Tondeuse thermique')

    get tool_url(@tool)

    assert_select 'h2', text: 'Activité'
    assert assigns(:audits).any? { |audit| audit.auditable_type == 'Tool' }
  end

  test 'show : l’historique ne répète pas les mouvements, déjà affichés au-dessus' do
    Mouvement.create!(tool: @tool, user: users(:bond), date: Date.today, état: :panne)

    get tool_url(@tool)

    assert_not assigns(:audits).any? { |audit| audit.auditable_type == 'Mouvement' }
  end

  test 'show : un agent ne reçoit pas l’historique des modifications' do
    sign_in users(:bond)

    get tool_url(@tool)

    assert_response :success
    assert_nil assigns(:audits)
  end

  test 'new : sans paramètre → la page répond' do
    get new_tool_url

    assert_response :success
  end

  test 'edit : un outil de son organisation → la page répond' do
    get edit_tool_url(@tool)

    assert_response :success
  end

  test 'create : paramètres valides → l’outil est créé' do
    assert_difference('Tool.count') do
      post tools_url, params: { tool: { name: nom_unique, description: @tool.description,
                                        organisation_id: @tool.organisation_id, icon_name: @tool.icon_name,
                                        modèle: @tool.modèle, marque: @tool.marque } }
    end

    assert_redirected_to tool_url(Tool.last)
  end

  test 'create : nom vide → aucune création et formulaire réaffiché' do
    assert_no_difference('Tool.count') do
      post tools_url, params: { tool: { name: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'update : paramètres valides → l’outil est modifié' do
    nouveau_nom = nom_unique

    patch tool_url(@tool), params: { tool: { name: nouveau_nom, description: @tool.description,
                                             icon_name: @tool.icon_name, modèle: @tool.modèle,
                                             marque: @tool.marque } }

    assert_redirected_to tool_url(@tool)
    assert_equal nouveau_nom, @tool.reload.name
  end

  test 'update : nom vidé → formulaire réaffiché en 422 et outil inchangé' do
    patch tool_url(@tool), params: { tool: { name: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @tool.reload.name
  end

  # ÉPINGLAGE B19 : la vue masque le bouton depuis #412, mais `destroy` ne garde
  # rien — une requête directe emporte l'outil et ses tool_interventions en
  # cascade. À inverser à la correction.
  test 'destroy : un outil utilisé par une intervention est quand même supprimé' do
    assert_predicate @tool.interventions, :any?

    delete tool_url(@tool)

    assert_not Tool.exists?(@tool.id)
  end

  test 'destroy : un outil inutilisé → il est supprimé' do
    assert_difference('Tool.count', -1) do
      delete tool_url(tools(:rateau))
    end

    assert_redirected_to tools_url
  end

  test 'set_tool : un slug inconnu redirige sans planter' do
    get tool_url(id: 'slug-inexistant')

    assert_redirected_to root_path
  end

  private

  def nom_unique = "#{@tool.name}-#{SecureRandom.hex(4)}"
end
