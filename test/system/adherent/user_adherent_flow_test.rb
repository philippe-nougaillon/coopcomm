# frozen_string_literal: true

require 'application_system_test_case'

class UserAdherentFlowTest < ApplicationSystemTestCase
  setup do
    @adhérent = users(:weil)
    login(@adhérent)
  end

  test 'Ne peut pas visiter la liste des utilisateurs' do
    visit users_url
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_no_text 'Utilisateurs'
  end
end
