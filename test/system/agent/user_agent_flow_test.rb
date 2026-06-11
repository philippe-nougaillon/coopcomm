# frozen_string_literal: true

require 'application_system_test_case'

class UserAgentFlowTest < ApplicationSystemTestCase
  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test 'Ne peut pas visiter la liste des utilisateurs' do
    visit users_url
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_no_text 'Utilisateurs'
  end
end
