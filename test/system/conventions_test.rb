require "application_system_test_case"

class ConventionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    @convention = conventions(:convention_paris)
    login(@admin)
  end

  def pdf_path
    Rails.root.join("test/fixtures/files/exemple.pdf").to_s
  end

  def image_path
    Rails.root.join("test/fixtures/files/exemple.png").to_s
  end

  test "la zone de dépôt s'affiche sur le formulaire d'édition" do
    visit edit_convention_path(@convention)

    assert_selector "[data-controller='dropzone']"
    assert_text "Glissez un fichier PDF ici ou cliquez pour parcourir"
  end

  test "déposer un fichier non PDF affiche une erreur et ne retient pas le fichier" do
    visit edit_convention_path(@convention)

    attach_file "convention_document", image_path, make_visible: true

    assert_text "Format non accepté"
    # La zone passe en rouge (couleur error daisyUI).
    assert_selector "[data-controller='dropzone'].border-error"
    # Le nom du fichier refusé ne remplace pas le libellé de la zone.
    assert_no_text "exemple.png"
  end

  test "déposer un PDF affiche son nom et l'enregistre" do
    visit edit_convention_path(@convention)

    attach_file "convention_document", pdf_path, make_visible: true

    assert_text "exemple.pdf"
    assert_no_text "Format non accepté"
    # La zone passe en vert (couleur success daisyUI).
    assert_selector "[data-controller='dropzone'].border-success"

    click_on "Enregistrer"

    assert_text "Convention mise à jour"
    assert @convention.reload.document.attached?, "le document aurait dû être attaché"
    assert_equal "exemple.pdf", @convention.document.filename.to_s
  end

  test "déposer un PDF après une erreur efface le message d'erreur" do
    visit edit_convention_path(@convention)

    attach_file "convention_document", image_path, make_visible: true
    assert_text "Format non accepté"
    assert_selector "[data-controller='dropzone'].border-error"

    attach_file "convention_document", pdf_path, make_visible: true
    assert_no_text "Format non accepté"
    assert_text "exemple.pdf"
    # Bascule rouge → vert, plus de classe d'erreur.
    assert_selector "[data-controller='dropzone'].border-success"
    assert_no_selector "[data-controller='dropzone'].border-error"
  end
end
