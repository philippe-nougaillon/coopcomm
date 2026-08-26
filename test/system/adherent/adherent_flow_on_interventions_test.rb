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

    all("[aria-label='Retirer ce fichier']").last.click
    assert_selector '[data-dropzone-target="fileList"] li', count: 1

    cliquer_bouton 'Enregistrer'

    assert_notification 'Intervention créée avec succès.'

    créée = Intervention.order(:created_at).last
    assert_equal services(:technique), créée.service
    assert_equal 1, créée.photos_demande.count
  end
end
