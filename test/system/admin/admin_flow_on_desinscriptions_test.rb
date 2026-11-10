# frozen_string_literal: true

require 'application_system_test_case'

class AdminFlowOnDesinscriptionsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    @app_instance = ENV.fetch('APP_INSTANCE', nil)
    ENV['APP_INSTANCE'] = 'demo'
    @admin = users(:administrateur_paris)
    login(@admin)
    fermer_notification
  end

  teardown do
    ENV['APP_INSTANCE'] = @app_instance
  end

  test "En tant qu'administrateur de la démonstration, je veux désactiver mon compte depuis ma fiche" do
    visit user_path(@admin)

    cliquer_bouton 'Désactiver mon compte'
    assert_selector '#delete_account_modal', text: 'Êtes-vous certain(e) de vouloir désactiver votre compte ?'
    cliquer_lien 'Oui, désactiver mon compte'

    assert_notification 'Au revoir ! Votre compte a bien été désactivé. Nous espérons vous revoir bientôt.'
    assert_current_path new_user_session_path
    assert @admin.reload.discarded?
  end

  test "En tant qu'administrateur de la démonstration, je veux supprimer mon organisation depuis sa page" do
    organisation = @admin.organisation
    visit organisation_path

    cliquer_bouton 'Supprimer mon organisation'
    assert_selector '#delete_organisation_modal', text: "Êtes-vous certain(e) de vouloir supprimer l'organisation « Mairie de Paris » ?"
    accept_confirm "Supprimer définitivement l'organisation « Mairie de Paris » ?" do
      cliquer_lien "Oui, supprimer l'organisation"
    end

    assert_notification 'Au revoir ! Votre organisation sera supprimée dans quelques instants. Nous espérons vous revoir bientôt.'
    assert_current_path new_user_session_path
    perform_enqueued_jobs only: SupprimerOrganisationJob
    assert_nil Organisation.find_by(id: organisation.id)
  end
end
