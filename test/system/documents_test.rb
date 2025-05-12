require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  setup do
    @tool = tools(:tondeuse)
    @document = documents(:carte_grise)

    login(users(:hidalgo))
  end

  test "should create document" do
    visit edit_tool_url(@tool)

    attach_file('tool_documents_attributes_0_fichier', 'test/fixtures/files/carte_grise.jpg')

    attach_file('tool_documents_attributes_1_fichier', 'test/fixtures/files/certificat_assurance.jpg')

    select("validé", from: "tool_documents_attributes_1_workflow_state")

    click_on "enregistrer_tool"

    assert_text "Outil modifié avec succès"
  end

  test "should validate document" do
    visit tool_url(@tool)

    assert_link "Valider", match: :first
    assert_link "Refuser", match: :first

    click_on "Valider", match: :first

    assert_selector "a.btn[disabled]", text: "Valider", match: :first
    assert_selector "a.btn[disabled]", text: "Refuser", match: :first
  end

  test "should refuse document" do
    visit tool_url(@tool)

    assert_link "Valider", match: :first
    assert_link "Refuser", match: :first

    click_on "Refuser", match: :first

    assert_selector "a.btn[disabled]", text: "Valider", match: :first
    assert_selector "a.btn[disabled]", text: "Refuser", match: :first
  end
end
