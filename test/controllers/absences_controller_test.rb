# frozen_string_literal: true

require 'test_helper'

class AbsencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:bond)
    @absence = absences(:one)
    sign_in users(:administrateur_paris)
  end

  test 'destroy : une absence de son périmètre → elle est supprimée' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence)
    end

    assert_redirected_to user_path(@agent)
  end

  test 'destroy : en turbo_stream → la section des absences est mise à jour' do
    assert_difference('Absence.count', -1) do
      delete absence_url(@absence), as: :turbo_stream
    end

    assert_response :success
    assert_match 'absences_section', response.body
    assert_match "absence_#{absences(:two).id}", response.body
    assert_no_match(/absence_#{@absence.id}\b/, response.body)
  end
end
