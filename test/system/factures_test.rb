require "application_system_test_case"

class FacturesTest < ApplicationSystemTestCase
  setup do
    @facture = factures(:one)
  end

  test "visiting the index" do
    visit factures_url
    assert_selector "h1", text: "Factures"
  end

  test "should create facture" do
    visit factures_url
    click_on "New facture"

    click_on "Create Facture"

    assert_text "Facture was successfully created"
    click_on "Back"
  end

  test "should update Facture" do
    visit facture_url(@facture)
    click_on "Edit this facture", match: :first

    click_on "Update Facture"

    assert_text "Facture was successfully updated"
    click_on "Back"
  end

  test "should destroy Facture" do
    visit facture_url(@facture)
    accept_confirm { click_on "Destroy this facture", match: :first }

    assert_text "Facture was successfully destroyed"
  end
end
