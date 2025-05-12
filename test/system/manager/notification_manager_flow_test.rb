require "application_system_test_case"

class NotificationManagerFlowTest < ApplicationSystemTestCase

  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test "Envoyer un message" do
    click_on "Messagerie"
    sleep(1)
    page.select "Bond", from: "user_id"
    fill_in "message", with: "Salut !!!"
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    assert_text "À Bond : Salut !!!"
  end

end