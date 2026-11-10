# frozen_string_literal: true

require 'test_helper'

class OrganisationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @app_instance = ENV.fetch('APP_INSTANCE', nil)
    ENV['APP_INSTANCE'] = 'demo'
    @administrateur = users(:administrateur_paris)
    @organisation = organisations(:mairie_paris)
    sign_in @administrateur
  end

  teardown do
    ENV['APP_INSTANCE'] = @app_instance
  end

  # ==================== TESTS CRITIQUES ====================
  # Supprimer l'organisation emporte ses services et tout ce qui s'y rattache : seul un
  # administrateur de l'instance de démonstration y a droit, et le travail part en job.

  test 'la suppression de l’organisation de l’administrateur connecté est mise en file (critique)' do
    organisation = @administrateur.organisation

    assert_enqueued_with(job: SupprimerOrganisationJob, args: [organisation.id]) do
      delete organisation_url
    end

    assert_redirected_to new_user_session_url
    assert_equal 'Au revoir ! Votre organisation sera supprimée dans quelques instants. Nous espérons vous revoir bientôt.',
                 flash[:notice]
    assert Organisation.exists?(organisation.id)
  end

  test 'un manager ne peut pas supprimer son organisation (critique)' do
    sign_in users(:hidalgo)

    assert_no_enqueued_jobs only: SupprimerOrganisationJob do
      delete organisation_url
    end

    assert_redirected_to root_path
    assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
  end

  test 'la suppression de l’organisation est introuvable hors de l’instance de démonstration (critique)' do
    ENV['APP_INSTANCE'] = 'production'

    assert_no_enqueued_jobs only: SupprimerOrganisationJob do
      delete organisation_url
    end

    assert_response :not_found
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la page de l’organisation est affichée avec succès' do
    get organisation_url

    assert_response :success
  end

  test 'la page de l’organisation affiche son nom' do
    get organisation_url

    assert_dom '#organisation', text: /Mairie de Paris/
  end

  test 'la page de l’organisation affiche son logo' do
    @organisation.update!(logo: fixture_file_upload('logo_organisation.png', 'image/png'))

    get organisation_url

    assert_dom '#organisation img[alt=?]', 'Mairie de Paris'
  end

  test 'la page de l’organisation compte les services, les sites et les prestations de l’organisation' do
    get organisation_url

    assert_equal @organisation.services.count, assigns(:services_count)
    assert_equal @organisation.warehouses.count, assigns(:warehouses_count)
    assert_equal @organisation.prestations.count, assigns(:prestations_count)
  end

  test 'la page de l’organisation est affichée hors de l’instance de démonstration' do
    ENV['APP_INSTANCE'] = 'production'

    get organisation_url

    assert_response :success
  end

  test 'la page de l’organisation propose sa suppression, confirmation comprise, sur l’instance de démonstration' do
    get organisation_url

    assert_dom 'a[href=?][data-turbo-method=delete][data-turbo-confirm=?]', organisation_path,
               "Supprimer définitivement l'organisation « Mairie de Paris » ?"
  end

  test 'la page de l’organisation ne propose pas sa suppression hors de l’instance de démonstration' do
    ENV['APP_INSTANCE'] = 'production'

    get organisation_url

    assert_dom 'a[href=?][data-turbo-method=delete]', organisation_path, count: 0
  end

  test 'la page de l’organisation affiche une version convertie de son logo' do
    @organisation.update!(logo: fixture_file_upload('logo_organisation.webp', 'image/webp'))

    get organisation_url

    assert_dom '#organisation img[src*=?]', '/representations/'
  end

  test 'le formulaire de l’organisation est affiché avec succès' do
    get edit_organisation_url

    assert_response :success
  end

  test 'le formulaire de l’organisation est prérempli avec son nom' do
    get edit_organisation_url

    assert_dom 'input[name=?][value=?]', 'organisation[nom]', 'Mairie de Paris'
  end

  test 'une organisation est renommée' do
    patch organisation_url, params: { organisation: { nom: 'Mairie de Lutèce' } }

    assert_redirected_to organisation_url
    assert_equal 'Organisation modifiée avec succès.', flash[:notice]
    assert_equal 'Mairie de Lutèce', @organisation.reload.nom
  end

  test 'un logo est ajouté à l’organisation' do
    patch organisation_url, params: { organisation: { logo: fixture_file_upload('logo_organisation.png', 'image/png') } }

    assert_redirected_to organisation_url
    assert @organisation.reload.logo.attached?
  end

  test 'une organisation au nom vide n’est pas enregistrée' do
    patch organisation_url, params: { organisation: { nom: '   ' } }

    assert_response :unprocessable_content
    assert_equal 'Mairie de Paris', @organisation.reload.nom
  end

  test 'un logo au format refusé n’est pas enregistré' do
    patch organisation_url, params: { organisation: { logo: fixture_file_upload('exemple.pdf', 'application/pdf') } }

    assert_response :unprocessable_content
    assert_not @organisation.reload.logo.attached?
  end

  test 'une organisation est renommée hors de l’instance de démonstration' do
    ENV['APP_INSTANCE'] = 'production'

    patch organisation_url, params: { organisation: { nom: 'Mairie de Lutèce' } }

    assert_equal 'Mairie de Lutèce', @organisation.reload.nom
  end

  test 'le logo de l’organisation est supprimé' do
    @organisation.update!(logo: fixture_file_upload('logo_organisation.png', 'image/png'))

    delete purge_logo_organisation_url

    assert_redirected_to organisation_url
    assert_equal 'Logo supprimé avec succès.', flash[:notice]
    assert_not @organisation.reload.logo.attached?
  end

  test 'la suppression du logo produit un audit qui la mentionne' do
    @organisation.update!(logo: fixture_file_upload('logo_organisation.png', 'image/png'))

    assert_difference -> { @organisation.audits.count }, 1 do
      delete purge_logo_organisation_url
    end

    assert_equal 'Logo supprimé', @organisation.audits.last.comment
  end
end
