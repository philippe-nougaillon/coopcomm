# frozen_string_literal: true

require 'test_helper'

class MouvementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @template_mouvement = mouvements(:mouvement_tondeuse)
    sign_in users(:administrateur_paris)
  end

  test 'should get index' do
    get mouvements_url
    assert_response :success
  end

  test 'should get show' do
    get mouvement_url(@template_mouvement)
    assert_response :not_found # Page non activé
  end

  test 'should get new' do
    get new_mouvement_url
    assert_response :success
  end

  test 'should create mouvement' do
    assert_difference('Mouvement.count') do
      post mouvements_url,
           params: { mouvement: { tool_id: @template_mouvement.tool_id, état: @template_mouvement.état,
                                  date: DateTime.now } }
    end

    assert_redirected_to Mouvement.last.tool
  end

  # Création invalide SANS outil imposé (arrivée via /mouvements/new sans tool_id) :
  # le select doit rester affiché pour que l'utilisateur corrige son choix.
  test 'create invalide sans tool_id imposé : le select reste affiché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url,
           params: { mouvement: { tool_id: @template_mouvement.tool_id, état: 'sortie', date: '' } }
    end

    assert_response :unprocessable_entity
    assert_select 'select[name=?]', 'mouvement[tool_id]'
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]', false
  end

  # Création invalide AVEC outil imposé (arrivée via new_mouvement_path(tool_id:)) :
  # le champ doit rester caché, l'outil ne devant pas être modifiable dans ce parcours.
  test 'create invalide avec tool_id imposé : le champ reste caché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url,
           params: { tool_id: @template_mouvement.tool_id,
                     mouvement: { tool_id: @template_mouvement.tool_id, état: 'sortie', date: '' } }
    end

    assert_response :unprocessable_entity
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]'
    assert_select 'select[name=?]', 'mouvement[tool_id]', false
  end

  test 'should get edit' do
    get edit_mouvement_url(@template_mouvement)
    assert_response :success
  end

  test 'should update mouvement' do
    patch mouvement_url(@template_mouvement),
          params: { mouvement: { tool_id: @template_mouvement.tool_id, état: @template_mouvement.état,
                                 date: DateTime.now + 1.day } }
    assert_redirected_to tool_path(@template_mouvement.tool)
  end
end
