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

  # ÉPINGLAGE BUG — la réponse turbo_stream rend `users/_absences_section`, qui
  # inclut lui-même `absence_form` : la recherche part de `absences/` et non de
  # `users/`, donc le partial est introuvable et l'action lève. À inverser à la
  # correction (préfixer le partial dans la vue).
  test 'destroy en turbo_stream lève sur un partial introuvable' do
    assert_raises(ActionView::Template::Error, ActionView::MissingTemplate) do
      delete absence_url(@absence), as: :turbo_stream
    end
  end

  test 'destroy en JSON ne renvoie aucun contenu' do
    delete absence_url(@absence), as: :json

    assert_response :no_content
  end

  test 'un adhérent ne peut pas supprimer l\'absence d\'un agent' do
    sign_in users(:weil)

    assert_no_difference('Absence.count') do
      delete absence_url(@absence)
    end

    assert_redirected_to root_path
  end
end
