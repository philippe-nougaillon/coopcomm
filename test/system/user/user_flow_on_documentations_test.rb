# frozen_string_literal: true

require 'application_system_test_case'

class UserFlowOnDocumentationsTest < ApplicationSystemTestCase
  test "En tant que visiteur non connecté, je veux consulter la documentation depuis la page d'accueil publique" do
    visit welcome_path

    cliquer_lien 'Consultez notre documentation (Blog / FAQ / ...)'

    assert_current_path documentation_index_path
    assert_text 'Bienvenue sur la documentation de CoopComm !'
  end
end
