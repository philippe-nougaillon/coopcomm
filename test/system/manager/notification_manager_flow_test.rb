# frozen_string_literal: true

require 'application_system_test_case'

class NotificationManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'Envoyer un message' do
    fermer_notification
    visit messagerie_path

    click_on users(:bond).nom_prénom
    fill_in 'message', with: 'Salut !!!'
    page.driver.browser.switch_to.active_element.send_keys(:enter)

    # L'adapter cable de test ne pousse pas le broadcast au navigateur :
    # on recharge la conversation pour vérifier la persistance.
    sleep(0.5)
    visit messagerie_conversation_path(users(:bond).id)
    assert_text 'Salut !!!'
  end
end
