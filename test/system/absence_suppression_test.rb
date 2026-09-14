require 'application_system_test_case'

class AbsenceSuppressionTest < ApplicationSystemTestCase

  #TODO : A revoir, devra etre testé pour un manager et pour un agent
  test 'un manager supprime une absence depuis la modale' do
    absence = absences(:one)
    login(users(:hidalgo))
    visit user_path(absence.user)

    within("#absence_#{absence.id}") { cliquer_bouton 'Modifier' }
    cliquer_bouton 'Supprimer'
    cliquer_lien 'Oui, supprimer'

    assert_no_selector "#absence_#{absence.id}", wait: 5
    assert_selector "#absence_#{absences(:two).id}"
    assert_nil Absence.find_by(id: absence.id)
  end
end
