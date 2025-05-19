require "application_system_test_case"

class NewslettersTest < ApplicationSystemTestCase
  setup do
    @newsletter = newsletters(:one)
  end

  test "visiting the index" do
    visit newsletters_url
    assert_selector "h1", text: "Newsletters"
  end

  test "should create newsletter" do
    visit newsletters_url
    click_on "New newsletter"

    fill_in "Email", with: @newsletter.email
    click_on "Create Newsletter"

    assert_text "Newsletter was successfully created"
    click_on "Back"
  end

  test "should update Newsletter" do
    visit newsletter_url(@newsletter)
    click_on "Edit this newsletter", match: :first

    fill_in "Email", with: @newsletter.email
    click_on "Update Newsletter"

    assert_text "Newsletter was successfully updated"
    click_on "Back"
  end

  test "should destroy Newsletter" do
    visit newsletter_url(@newsletter)
    click_on "Destroy this newsletter", match: :first

    assert_text "Newsletter was successfully destroyed"
  end
end
