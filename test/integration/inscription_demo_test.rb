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
    assert_dom 'a[href=?]', new_user_registration_path, text: "S'inscrire"

    get new_user_registration_path
    assert_response :success
  end

  test "En tant que visiteur d'une instance hors démonstration, je ne veux pas qu'on me propose de m'inscrire" do
    ENV['APP_INSTANCE'] = 'production'

    get new_user_session_path

    assert_dom 'a[href=?]', new_user_registration_path, count: 0
  end

  test "En tant que visiteur de la démonstration, je veux arriver connecté sur l'accueil de ma nouvelle organisation après mon inscription" do
    post user_registration_path, params: { user: { prénom: 'Jeanne', nom: 'Dupont', email: 'jeanne.dupont@exemple.fr',
                                                   nom_organisation: 'Mairie de Test', noms_services: ['', 'Technique'],
                                                   password: 'Motdepasse12!', password_confirmation: 'Motdepasse12!' } }
    follow_redirect!

    assert_response :success
    assert_dom 'li[title=?]', User.find_by!(email: 'jeanne.dupont@exemple.fr').nom_prenom_role
  end
end
