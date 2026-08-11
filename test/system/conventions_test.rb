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

  def fichier_refusé_path
    Rails.root.join('test/fixtures/files/responseMeteoConcept.json').to_s
  end

  test "la zone de dépôt s'affiche sur le formulaire" do
    visit new_convention_path

    assert_selector "[data-controller='dropzone']"
    assert_text 'Glissez un document (PDF, Word, Excel, photo) ici ou cliquez pour parcourir'
  end

  test 'déposer un fichier au mauvais format affiche une erreur et ne retient pas le fichier' do
    visit new_convention_path

    attach_file 'convention_document', fichier_refusé_path, make_visible: true

    assert_text 'Format non accepté'
    # La zone passe en rouge (couleur error daisyUI).
    assert_selector "[data-controller='dropzone'][data-dropzone-state='error']"
    # Le nom du fichier refusé ne remplace pas le libellé de la zone.
    assert_no_text 'responseMeteoConcept.json'
  end

  test 'survoler la zone avec un fichier annonce visuellement le dépôt' do
    visit new_convention_path

    survoler_avec_un_fichier
    assert_selector "[data-controller='dropzone'][data-dropzone-dragging]"
    assert_text 'Déposez le fichier ici'

    # Passer d'un enfant à l'autre ne doit pas faire clignoter l'effet.
    quitter_vers "document.querySelector(\"[data-controller='dropzone'] svg\")"
    assert_selector "[data-controller='dropzone'][data-dropzone-dragging]"

    quitter_vers 'document.body'
    assert_no_selector "[data-controller='dropzone'][data-dropzone-dragging]"
    assert_text 'Glissez un document (PDF, Word, Excel, photo) ici ou cliquez pour parcourir'
  end

  test 'la zone annonce les formats acceptés et la taille maximale' do
    visit new_convention_path

    assert_text 'Formats acceptés : PDF, DOC, DOCX'
    assert_text '20 Mo maximum par fichier'
  end

  test 'un fichier de plus de 20 Mo est refusé sans être envoyé' do
    visit new_convention_path

    gros = Tempfile.new(['gros', '.pdf'])
    gros.write('0' * 21.megabytes)
    gros.flush
    attach_file 'convention_document', gros.path, make_visible: true

    assert_text 'Fichier trop volumineux. Taille maximale : 20 Mo.'
    assert_selector "[data-controller='dropzone'][data-dropzone-state='error']"
    # Le champ est vidé : rien ne part au serveur.
    assert_equal 0, evaluate_script("document.querySelector('#convention_document').files.length")
  end

  test 'déposer la photo du document signé est accepté' do
    visit new_convention_path

    attach_file 'convention_document', image_path, make_visible: true

    assert_no_text 'Format non accepté'
    assert_selector "[data-controller='dropzone'][data-dropzone-state='success']"
  end

  test "déposer un PDF affiche son nom et l'enregistre" do
    visit new_convention_path

    attach_file 'convention_document', pdf_path, make_visible: true

    assert_text 'exemple.pdf'
    assert_no_text 'Format non accepté'
    # La zone passe en vert (couleur success daisyUI).
    assert_selector "[data-controller='dropzone'][data-dropzone-state='success']"

    select_option '#convention_user_id', 'Bruel Patrick'
    assert_selector '#convention_service_id option', text: 'Service_Paris', visible: false, wait: 5
    select_option '#convention_service_id', 'Service_Paris'
    fill_in 'convention_date_début', with: Date.current
    fill_in 'convention_date_fin_prévue', with: Date.current + 1.year
    fill_in 'convention_heures_conventionnees', with: 10

    cliquer_bouton 'Enregistrer'

    # État métier plutôt que le toast (il s'auto-détruit au bout de 5 s) :
    # `create` redirige vers l'index, c'est ça le signal fiable de succès.
    assert_current_path conventions_path
    créée = users(:patrick_adherent_paris).conventions.last
    assert créée.document.attached?, 'le document aurait dû être attaché'
    assert_equal 'exemple.pdf', créée.document.filename.to_s
  end

  test "déposer un PDF après une erreur efface le message d'erreur" do
    visit new_convention_path

    attach_file 'convention_document', fichier_refusé_path, make_visible: true
    assert_text 'Format non accepté'
    assert_selector "[data-controller='dropzone'][data-dropzone-state='error']"

    attach_file 'convention_document', pdf_path, make_visible: true
    assert_no_text 'Format non accepté'
    assert_text 'exemple.pdf'
    # Bascule rouge → vert, plus de classe d'erreur.
    assert_selector "[data-controller='dropzone'][data-dropzone-state='success']"
    assert_no_selector "[data-controller='dropzone'][data-dropzone-state='error']"
  end

  # --- Liste de services dépendante de l'adhérent (controller dynamic-select) ---

  test "le choix de l'adhérent peuple dynamiquement la liste des services" do
    visit new_convention_path

    # patrick (Bruel Patrick) est rattaché au seul service Service_Paris, sans convention
    select_option '#convention_user_id', 'Bruel Patrick'

    # le JS appelle services_for_adherent et injecte les <option> dans le select (caché par slim_select)
    assert_selector '#convention_service_id option', text: 'Service_Paris', visible: false, wait: 5
  end

  private

  # Selenium ne sait pas glisser un fichier du bureau vers la page : on émet les
  # évènements de survol que le navigateur enverrait, depuis un enfant de la zone.
  def survoler_avec_un_fichier
    execute_script(<<~JS)
      const enfant = document.querySelector("[data-dropzone-target='filename']");
      const dt = new DataTransfer();
      ['dragenter', 'dragover'].forEach(nom => {
        enfant.dispatchEvent(new DragEvent(nom, { bubbles: true, cancelable: true, dataTransfer: dt }));
      });
    JS
  end

  def quitter_vers(cible_js)
    execute_script(<<~JS)
      document.querySelector("[data-dropzone-target='filename']").dispatchEvent(
        new DragEvent('dragleave', { bubbles: true, cancelable: true, relatedTarget: #{cible_js} })
      );
    JS
  end
end
