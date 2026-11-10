# frozen_string_literal: true

require 'application_system_test_case'

class AdminFlowOnOrganisationsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    @organisation = @admin.organisation
    login(@admin)
    fermer_notification
  end

  test "En tant qu'administrateur, je veux supprimer le logo de mon organisation" do
    @organisation.update!(logo: { io: file_fixture('logo_organisation.png').open, filename: 'logo_organisation.png',
                                  content_type: 'image/png' })
    visit organisation_path

    cliquer_element(element_testid('supprimer_logo'))
    assert_selector '#delete_logo_modal', text: 'Êtes-vous certain(e) de vouloir supprimer le logo ?'
    cliquer_bouton 'Oui, supprimer'

    assert_notification 'Logo supprimé avec succès.'
    assert_text 'Non renseigné : logo de CoopComm'
    assert_not @organisation.reload.logo.attached?
  end

  test "En tant qu'administrateur, je veux savoir pourquoi mon organisation n'est pas enregistrée sans nom" do
    visit edit_organisation_path

    fill_in 'organisation_nom', with: '   '
    cliquer_bouton 'Enregistrer'

    within find_error_form do
      assert_text 'Nom doit être rempli(e)'
    end
    assert_equal 'Mairie de Paris', @organisation.reload.nom
  end
end
