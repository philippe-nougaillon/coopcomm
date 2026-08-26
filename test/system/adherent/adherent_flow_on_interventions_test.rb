# frozen_string_literal: true

require 'application_system_test_case'

class AdherentFlowOnInterventionsTest < ApplicationSystemTestCase
  setup do
    @adherent = users(:weil)

    login(@adherent)
    fermer_notification
  end

  test 'une demande d’intervention est créée avec son service et ses photos' do
    cliquer_element(element_testid('menu_interventions'))
    click_sur_boutton_ajouter('intervention')

    fill_in 'Description', with: 'Remplacer une ampoule du hall'
    select_option('#intervention_service_id', 'Technique')
    fermer_menus_slim_select

    # L'input de la dropzone est masqué : c'est la zone qui le déclenche à l'écran.
    attach_file 'intervention_photos_demande',
                [file_fixture('exemple.png'), file_fixture('carte_grise.jpg')].map(&:to_s),
                make_visible: true
    assert_selector '[data-dropzone-target="fileList"] li', count: 2
    assert_link 'exemple.png'

    all("[aria-label='Retirer ce fichier']").last.click
    assert_selector '[data-dropzone-target="fileList"] li', count: 1

    cliquer_bouton 'Enregistrer'

    assert_notification 'Intervention créée avec succès.'

    créée = Intervention.order(:created_at).last
    assert_equal services(:technique), créée.service
    assert_equal 1, créée.photos_demande.count
  end

  test "En tant qu'adhérent, je veux retrouver les photos déjà envoyées quand je modifie ma demande" do
    intervention = interventions(:tonte_locaux)
    intervention.photos_demande.attach(io: file_fixture('exemple.png').open, filename: 'exemple.png')

    visit edit_intervention_path(intervention.slug)

    within element_testid('dropzone_photos_demande') do
      assert_text 'Fichiers actuels'
      assert_selector 'li', text: 'exemple.png'
      assert_link 'exemple.png'
    end
  end

  test "En tant qu'adhérent, je veux être averti quand la fin prévue de mon intervention précède son début" do
    visit new_intervention_path

    fill_in 'Description', with: 'Remplacer une ampoule du hall'
    select_option('#intervention_service_id', 'Technique')
    fermer_menus_slim_select

    fill_in 'intervention[début_prévue]', with: Date.current + 3
    fill_in 'intervention[fin_prévue]', with: Date.current + 2

    cliquer_bouton 'Enregistrer'

    within find_error_form do
      assert_text "1 erreur empêche(nt) cette intervention d'être sauvegardée :"
      assert_text "Erreur : La fin prévue de l'intervention ne peut pas être avant son commencement"
    end
  end
end
