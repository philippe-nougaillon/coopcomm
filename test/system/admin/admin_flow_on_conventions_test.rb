# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../../support/faux_modele'

class AdminFlowOnConventionsTest < ApplicationSystemTestCase
  include FauxModele

  setup do
    brancher_faux_modele
    @admin = users(:administrateur_paris)
    login(@admin)
    fermer_notification
  end

  teardown do
    debrancher_faux_modele
  end

  test "En tant qu'administrateur, je veux déposer une convention à analyser depuis la fenêtre d'importation" do
    visit analyses_conventions_path

    cliquer_element(element_testid('importer_conventions'))
    attach_file 'convention_document', Rails.root.join('test/fixtures/files/exemple.pdf').to_s, make_visible: true
    cliquer_bouton "Lancer l'importation"

    assert_notification "1 document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué."
    convention = Convention.order(:id).last
    assert_equal [@admin, Convention::EN_ATTENTE], [convention.deposant, convention.workflow_state]
    assert_selector "tr#convention_#{convention.id}", text: 'En attente'
  end
end
