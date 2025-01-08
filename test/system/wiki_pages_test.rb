require "application_system_test_case"

class WikiPagesTest < ApplicationSystemTestCase
  setup do
    @wiki_page = wiki_pages(:one)
  end

  test "visiting the index" do
    visit wiki_pages_url
    assert_selector "h1", text: "Wiki pages"
  end

  test "should create wiki page" do
    visit wiki_pages_url
    click_on "New wiki page"

    fill_in "Nom", with: @wiki_page.nom
    fill_in "Poids", with: @wiki_page.poids
    check "Publié" if @wiki_page.publié
    click_on "Create Wiki page"

    assert_text "Wiki page was successfully created"
    click_on "Back"
  end

  test "should update Wiki page" do
    visit wiki_page_url(@wiki_page)
    click_on "Edit this wiki page", match: :first

    fill_in "Nom", with: @wiki_page.nom
    fill_in "Poids", with: @wiki_page.poids
    check "Publié" if @wiki_page.publié
    click_on "Update Wiki page"

    assert_text "Wiki page was successfully updated"
    click_on "Back"
  end

  test "should destroy Wiki page" do
    visit wiki_page_url(@wiki_page)
    click_on "Destroy this wiki page", match: :first

    assert_text "Wiki page was successfully destroyed"
  end
end
