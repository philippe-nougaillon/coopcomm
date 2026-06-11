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
