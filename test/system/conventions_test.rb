# frozen_string_literal: true

require 'application_system_test_case'

class ConventionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    @convention = conventions(:convention_paris)
    login(@admin)
  end

  def pdf_path
    Rails.root.join('test/fixtures/files/exemple.pdf').to_s
  end

  def image_path
    Rails.root.join('test/fixtures/files/exemple.png').to_s
  end

  test "la zone de dépôt s'affiche sur le formulaire d'édition" do
    visit edit_convention_path(@convention)

    assert_selector "[data-controller='dropzone']"
    assert_text 'Glissez un fichier PDF ici ou cliquez pour parcourir'
  end

  test 'déposer un fichier non PDF affiche une erreur et ne retient pas le fichier' do
    visit edit_convention_path(@convention)

    attach_file 'convention_document', image_path, make_visible: true

    assert_text 'Format non accepté'
    # La zone passe en rouge (couleur error daisyUI).
    assert_selector "[data-controller='dropzone'].border-error"
    # Le nom du fichier refusé ne remplace pas le libellé de la zone.
    assert_no_text 'exemple.png'
  end

  test "déposer un PDF affiche son nom et l'enregistre" do
    visit edit_convention_path(@convention)

    attach_file 'convention_document', pdf_path, make_visible: true

    assert_text 'exemple.pdf'
    assert_no_text 'Format non accepté'
    # La zone passe en vert (couleur success daisyUI).
    assert_selector "[data-controller='dropzone'].border-success"

    cliquer_bouton 'Enregistrer'

    # État métier plutôt que le toast (il s'auto-détruit au bout de 5 s) :
    # `update` redirige vers l'index, c'est ça le signal fiable de succès.
    assert_current_path conventions_path
    assert @convention.reload.document.attached?, 'le document aurait dû être attaché'
    assert_equal 'exemple.pdf', @convention.document.filename.to_s
  end

  test "déposer un PDF après une erreur efface le message d'erreur" do
    visit edit_convention_path(@convention)

    attach_file 'convention_document', image_path, make_visible: true
    assert_text 'Format non accepté'
    assert_selector "[data-controller='dropzone'].border-error"

    attach_file 'convention_document', pdf_path, make_visible: true
    assert_no_text 'Format non accepté'
    assert_text 'exemple.pdf'
    # Bascule rouge → vert, plus de classe d'erreur.
    assert_selector "[data-controller='dropzone'].border-success"
    assert_no_selector "[data-controller='dropzone'].border-error"
  end

  # --- Liste de services dépendante de l'adhérent (controller dynamic-select) ---

  test "le choix de l'adhérent peuple dynamiquement la liste des services" do
    visit new_convention_path

    # patrick (Bruel Patrick) est rattaché au seul service Service_Paris, sans convention
    select_option '#convention_user_id', 'Bruel Patrick'

    # le JS appelle services_for_adherent et injecte les <option> dans le select (caché par slim_select)
    assert_selector '#convention_service_id option', text: 'Service_Paris', visible: false, wait: 5
  end
end
