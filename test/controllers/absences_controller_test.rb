# frozen_string_literal: true

require 'test_helper'

class AbsencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:bond)
    @absence = absences(:one)
    sign_in users(:administrateur_paris)
  end

  test 'une absence est supprimée' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence)
    end

    assert_redirected_to user_path(@agent)
  end

  test 'une absence supprimée en turbo stream est retirée de la section des absences' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence), as: :turbo_stream
    end

    assert_response :success
    assert_match 'absences_section', response.body
    assert_match "absence_#{absences(:two).id}", response.body
    assert_no_match(/absence_#{@absence.id}\b/, response.body)
  end
end
