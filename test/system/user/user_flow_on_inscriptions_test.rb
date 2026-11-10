# frozen_string_literal: true

require 'application_system_test_case'

class UserFlowOnInscriptionsTest < ApplicationSystemTestCase
  setup do
    @app_instance = ENV.fetch('APP_INSTANCE', nil)
    ENV['APP_INSTANCE'] = 'demo'
  end

  teardown do
    ENV['APP_INSTANCE'] = @app_instance
  end

  test "En tant que visiteur de la démonstration, je veux créer mon compte et mon organisation avec ses services" do
    visit new_user_registration_path

    fill_in 'user_prénom', with: 'Jeanne'
    fill_in 'user_nom', with: 'Dupont'
    fill_in 'user_email', with: 'jeanne.dupont@exemple.fr'
    fill_in 'user_nom_organisation', with: 'Mairie de Test'
    ajouter_service 'Voirie'
    fill_in 'user_password', with: 'Motdepasse12!'
    fill_in 'user_password_confirmation', with: 'Motdepasse12!'
    cliquer_bouton "S'inscrire"

    assert_notification 'Un message avec un lien de confirmation vous a été envoyé par mail.'
    assert_equal %w[Technique Voirie], User.find_by!(email: 'jeanne.dupont@exemple.fr').services.map(&:nom).sort
  end

  test "En tant que visiteur de la démonstration, je veux savoir pourquoi mon inscription est refusée" do
    visit new_user_registration_path

    fill_in 'user_prénom', with: 'Jeanne'
    fill_in 'user_nom', with: 'Dupont'
    fill_in 'user_email', with: users(:hidalgo).email
    fill_in 'user_nom_organisation', with: 'Mairie de Test'
    fill_in 'user_password', with: 'Motdepasse12!'
    fill_in 'user_password_confirmation', with: 'Motdepasse13!'
    cliquer_bouton "S'inscrire"

    within '#error_explanation' do
      assert_selector 'li', count: 2
      assert_selector 'li', text: 'Email est déjà utilisé(e)'
      assert_selector 'li', text: 'Confirmation du mot de passe ne concorde pas avec Mot de passe'
    end
  end

  test "En tant que visiteur de la démonstration, je veux savoir que le nom de mon organisation manque quand je n'y ai mis que des espaces" do
    visit new_user_registration_path

    fill_in 'user_prénom', with: 'Jeanne'
    fill_in 'user_nom', with: 'Dupont'
    fill_in 'user_email', with: 'jeanne.dupont@exemple.fr'
    fill_in 'user_nom_organisation', with: '   '
    fill_in 'user_password', with: 'Motdepasse12!'
    fill_in 'user_password_confirmation', with: 'Motdepasse12!'
    cliquer_bouton "S'inscrire"

    within '#error_explanation' do
      assert_selector 'li', count: 1
      assert_selector 'li', text: 'Organisation doit être rempli(e)'
    end
  end

  private

  # Le service n'existe pas encore : slim-select (`addable`) l'ajoute quand on tape son nom puis Entrée.
  def ajouter_service(nom)
    activate_dropdown_slimSelect('#user_noms_services')
    find('.ss-search input', visible: true).set(nom).send_keys(:enter)
    fermer_menus_slim_select
  end
end
