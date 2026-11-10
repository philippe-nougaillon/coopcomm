# frozen_string_literal: true

require 'test_helper'

class InscriptionDemoTest < ActionDispatch::IntegrationTest
  setup do
    @app_instance = ENV.fetch('APP_INSTANCE', nil)
    ENV['APP_INSTANCE'] = 'demo'
  end

  teardown do
    ENV['APP_INSTANCE'] = @app_instance
  end

  test "En tant que visiteur de la démonstration, je veux trouver l'inscription depuis la page de connexion" do
    get new_user_session_path
    assert_dom 'main a[href=?]', new_user_registration_path, text: "S'inscrire"

    get new_user_registration_path
    assert_response :success
  end

  test "En tant que visiteur d'une instance hors démonstration, je ne veux pas qu'on me propose de m'inscrire depuis le formulaire de connexion" do
    ENV['APP_INSTANCE'] = 'production'

    get new_user_session_path

    assert_dom 'main a[href=?]', new_user_registration_path, count: 0
  end

  test "En tant que visiteur de la démonstration, je veux trouver l'inscription depuis la page d'accueil" do
    get root_path
    assert_dom 'main a[href=?]', new_user_registration_path, text: "S'inscrire"

    get new_user_registration_path
    assert_response :success
  end

  test "En tant que visiteur de la démonstration, je veux trouver l'inscription depuis la barre de navigation" do
    get root_path
    assert_dom 'nav a[href=?]', new_user_registration_path, text: "S'inscrire"
    assert_dom '#menu-mobile a[href=?]', new_user_registration_path, text: "S'inscrire"

    get new_user_registration_path
    assert_response :success
  end

  test "En tant que visiteur de la démonstration, je veux trouver le renvoi du mail de confirmation depuis la page de connexion" do
    get new_user_session_path
    assert_dom 'main a[href=?]', new_user_confirmation_path, text: 'Le recevoir à nouveau'

    get new_user_confirmation_path
    assert_response :success
  end

  test "En tant que visiteur de la démonstration, je veux arriver sur l'accueil de ma nouvelle organisation après avoir confirmé mon adresse" do
    post user_registration_path, params: inscription
    get lien_de_confirmation(ActionMailer::Base.deliveries.last)
    follow_redirect!

    assert_dom '#notification', text: /Votre compte a bien été confirmé/

    post user_session_path, params: { user: { email: 'jeanne.dupont@exemple.fr', password: 'Motdepasse12!' } }
    follow_redirect!

    assert_response :success
    assert_dom 'li[title=?]', User.find_by!(email: 'jeanne.dupont@exemple.fr').nom_prenom_role
  end

  test "En tant que visiteur de la démonstration, je veux être prévenu après mon inscription qu'un mail de confirmation m'attend" do
    post user_registration_path, params: inscription
    follow_redirect!

    assert_dom '#notification', text: /lien de confirmation vous a été envoyé/
  end

  test "En tant que visiteur de la démonstration, je veux savoir que je dois confirmer mon adresse avant de pouvoir me connecter" do
    post user_registration_path, params: inscription
    post user_session_path, params: { user: { email: 'jeanne.dupont@exemple.fr', password: 'Motdepasse12!' } }
    follow_redirect!

    assert_dom '#notification', text: /Vous devez confirmer votre compte par email/

    get users_path
    assert_redirected_to new_user_session_path
  end

  test "En tant qu'administrateur de la démonstration, je veux retrouver la connexion et l'inscription après avoir désactivé mon compte" do
    sign_in users(:administrateur_paris)

    delete user_registration_path
    follow_redirect!

    assert_response :success
    assert_dom 'a[href=?]', new_user_registration_path, text: "S'inscrire"

    get users_path
    assert_redirected_to new_user_session_path
  end

  test "En tant qu'administrateur de la démonstration, je veux retrouver la connexion et l'inscription après avoir supprimé mon organisation" do
    sign_in users(:administrateur_paris)

    delete organisation_path
    follow_redirect!

    assert_response :success
    assert_dom 'a[href=?]', new_user_registration_path, text: "S'inscrire"

    get users_path
    assert_redirected_to new_user_session_path
  end

  private

  def inscription
    { user: { prénom: 'Jeanne', nom: 'Dupont', email: 'jeanne.dupont@exemple.fr',
              nom_organisation: 'Mairie de Test', noms_services: ['', 'Technique'],
              password: 'Motdepasse12!', password_confirmation: 'Motdepasse12!' } }
  end

  def lien_de_confirmation(mail)
    Nokogiri::HTML(mail.body.to_s).at_css('a[href*="confirmation_token="]')['href']
  end
end
