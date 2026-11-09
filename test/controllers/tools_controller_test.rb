# frozen_string_literal: true

require 'test_helper'

class ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tool = tools(:tondeuse)
    sign_in users(:hidalgo)
  end

  test 'la liste du matériel est affichée avec succès' do
    get tools_url

    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le matériel d’une autre organisation n’apparaît pas dans la liste (critique)' do
    get tools_url

    assert_not_includes assigns(:tools), tools(:camion)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la liste du matériel s’ouvre sur la semaine en cours' do
    get tools_url

    assert_equal Date.today.beginning_of_week, assigns(:date)
    assert_equal Date.today.end_of_week, assigns(:date_fin)
  end

  test 'la liste du matériel s’ouvre sur la semaine qui contient la date demandée' do
    jeudi = Date.new(2026, 6, 4)

    get tools_url(date: jeudi.to_s)

    assert_equal jeudi.beginning_of_week, assigns(:date)
    assert_equal jeudi.end_of_week, assigns(:date_fin)
  end

  test 'une date illisible ramène la liste du matériel à la semaine en cours' do
    get tools_url(date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_week, assigns(:date)
  end

  test 'la recherche dans la liste ne retourne que le matériel correspondant' do
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

  test 'un outil est affiché avec succès' do
    get tool_url(@tool)

    assert_response :success
  end

  test 'la fiche d’un outil s’ouvre sur le mois qui contient la date demandée et la grille qui l’entoure' do
    quinze = Date.new(2026, 6, 15)

    get tool_url(@tool, date: quinze.to_s)

    assert_equal quinze.beginning_of_month, assigns(:date)
    assert_equal quinze.end_of_month, assigns(:date_fin)
    assert_equal quinze.beginning_of_month.beginning_of_week, assigns(:date_inicio_grid)
    assert_equal quinze.end_of_month.end_of_week, assigns(:date_fin_grid)
  end

  test 'une date illisible ramène la fiche d’un outil au mois en cours' do
    get tool_url(@tool, date: 'pas-une-date')

    assert_response :success
    assert_equal Date.today.beginning_of_month, assigns(:date)
  end

  # Les flèches du calendrier émettent start_date sans effacer un date= plus ancien :
  # la grille d'états doit suivre le mois réellement affiché.
  test 'la date émise par les flèches du calendrier prime sur une date plus ancienne restée dans l’adresse' do
    get tool_url(@tool, date: '2026-01-05', start_date: '2026-06-15')

    assert_equal Date.new(2026, 6, 1), assigns(:date)
    assert_equal Date.new(2026, 6, 1).beginning_of_week, assigns(:date_inicio_grid)
  end

  test 'un manager reçoit l’historique des modifications de l’outil' do
    @tool.update!(name: 'Tondeuse thermique')

    get tool_url(@tool)

    assert_select 'h2', text: 'Activité'
    assert assigns(:audits).any? { |audit| audit.auditable_type == 'Tool' }
  end

  test 'l’historique d’un outil ne répète pas les mouvements, déjà affichés au-dessus' do
    Mouvement.create!(tool: @tool, user: users(:bond), date: Date.today, état: :panne)

    get tool_url(@tool)

    assert_not assigns(:audits).any? { |audit| audit.auditable_type == 'Mouvement' }
  end

  test 'un agent ne reçoit pas l’historique des modifications de l’outil' do
    sign_in users(:bond)

    get tool_url(@tool)

    assert_response :success
    assert_nil assigns(:audits)
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_tool_url

    assert_response :success
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_tool_url(@tool)

    assert_response :success
  end

  test 'un outil est créé lorsque les paramètres sont valides' do
    assert_difference('Tool.count') do
      post tools_url, params: { tool: { name: nom_unique, description: @tool.description,
                                        organisation_id: @tool.organisation_id, icon_name: @tool.icon_name,
                                        modèle: @tool.modèle, marque: @tool.marque } }
    end

    assert_redirected_to tool_url(Tool.last)
  end

  test 'un outil sans nom n’est pas créé' do
    assert_no_difference('Tool.count') do
      post tools_url, params: { tool: { name: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'un outil est modifié lorsque les paramètres sont valides' do
    nouveau_nom = nom_unique

    patch tool_url(@tool), params: { tool: { name: nouveau_nom, description: @tool.description,
                                             icon_name: @tool.icon_name, modèle: @tool.modèle,
                                             marque: @tool.marque } }

    assert_redirected_to tool_url(@tool)
    assert_equal nouveau_nom, @tool.reload.name
  end

  test 'un outil dont le nom est vidé n’est pas modifié' do
    patch tool_url(@tool), params: { tool: { name: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @tool.reload.name
  end

  # ÉPINGLAGE B19 : la vue masque le bouton depuis #412, mais `destroy` ne garde
  # rien — une requête directe emporte l'outil et ses tool_interventions en
  # cascade. À inverser à la correction.
  test 'un outil utilisé par une intervention est quand même supprimé' do
    assert_predicate @tool.interventions, :any?

    delete tool_url(@tool)

    assert_not Tool.exists?(@tool.id)
  end

  test 'un outil inutilisé est supprimé' do
    assert_difference('Tool.count', -1) do
      delete tool_url(tools(:rateau))
    end

    assert_redirected_to tools_url
  end

  test 'un slug d’outil inconnu redirige sans planter' do
    get tool_url(id: 'slug-inexistant')

    assert_redirected_to root_path
  end

  private

  def nom_unique = "#{@tool.name}-#{SecureRandom.hex(4)}".upcase
end
