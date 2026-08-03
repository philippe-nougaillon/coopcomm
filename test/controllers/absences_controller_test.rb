# frozen_string_literal: true

require 'test_helper'

class AbsencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:bond)
    @absence = absences(:one)
    sign_in users(:hidalgo)
  end

  test 'destroy supprime l\'absence et revient à la fiche de l\'agent' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence)
    end

    assert_redirected_to user_path(@agent)
  end

  test 'destroy en turbo_stream met à jour la section des absences' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence), as: :turbo_stream
    end

    assert_response :success
    assert_match 'absences_section', response.body
    assert_match "absence_#{absences(:two).id}", response.body
    assert_no_match(/absence_#{@absence.id}\b/, response.body)
  end

  test 'destroy en JSON ne renvoie aucun contenu' do
    delete absence_url(@absence), as: :json

    assert_response :no_content
  end

  test 'un agent ne peut pas supprimer sa propre absence' do
    sign_in @agent

    assert_no_difference('Absence.count') do
      delete absence_url(@absence)
    end

    assert_redirected_to root_path
  end

  test 'un adhérent ne peut pas supprimer l\'absence d\'un agent' do
    sign_in users(:weil)

    assert_no_difference('Absence.count') do
      delete absence_url(@absence)
    end

    assert_redirected_to root_path
  end
end
