# frozen_string_literal: true

require 'application_system_test_case'

class ManagerFlowOnMessagesTest < ApplicationSystemTestCase
  setup do
    login(users(:hidalgo))
  end

  test "En tant que manager, je veux trouver un contact par la recherche quand les messages privés sont repliés" do
    visit messagerie_path
    ouvrir_contacts
    cliquer_element(find('summary', text: 'MESSAGE PRIVÉ'))
    assert_no_link 'Weil Ariel'

    fill_in 'query', with: 'Weil'

    assert_link 'Weil Ariel'
  end
end
