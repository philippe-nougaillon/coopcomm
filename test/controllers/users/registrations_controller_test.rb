# frozen_string_literal: true

require 'test_helper'

module Users
  class RegistrationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @app_instance = ENV.fetch('APP_INSTANCE', nil)
      ENV['APP_INSTANCE'] = 'demo'
    end

    teardown do
      ENV['APP_INSTANCE'] = @app_instance
    end

    test "le formulaire d'inscription s'affiche sur l'instance de démonstration" do
      get new_user_registration_url

      assert_response :success
    end

    test "le formulaire d'inscription est introuvable hors de l'instance de démonstration" do
      ENV['APP_INSTANCE'] = 'production'

      get new_user_registration_url

      assert_response :not_found
    end

    test "une inscription mène à l'accueil avec un message de bienvenue" do
      post user_registration_url, params: inscription

      assert_redirected_to root_url
      assert_equal 'Bienvenue ! Votre compte a bien été créé.', flash[:notice]
    end

    test "une inscription n'est pas enregistrée hors de l'instance de démonstration" do
      ENV['APP_INSTANCE'] = 'production'

      assert_no_difference %w[User.count Organisation.count Service.count] do
        post user_registration_url, params: inscription
      end

      assert_response :not_found
    end

    test 'une inscription rend administrateur' do
      post user_registration_url, params: inscription

      assert User.find_by!(email: 'jeanne.dupont@exemple.fr').administrateur?
    end

    test "le nom d'organisation est enregistré sans les espaces qui l'entourent" do
      post user_registration_url, params: inscription.deep_merge(user: { nom_organisation: '  Mairie de Test  ' })

      assert_equal 'Mairie de Test', User.find_by!(email: 'jeanne.dupont@exemple.fr').organisation.nom
    end

    # ==================== TESTS CRITIQUES ====================
    # L'organisation de l'inscrit dérive des services créés à l'inscription : c'est elle
    # qui le cloisonne des autres organisations de l'instance.

    test "une inscription crée l'organisation saisie et y rattache l'inscrit par les services saisis (critique)" do
      post user_registration_url, params: inscription

      inscrit = User.find_by!(email: 'jeanne.dupont@exemple.fr')
      assert_equal 'Mairie de Test', inscrit.organisation.nom
      assert_equal %w[Technique Voirie], inscrit.services.map(&:nom).sort
      assert_equal [inscrit.organisation], inscrit.services.map(&:organisation).uniq
    end

    test "un service saisi deux fois avec une casse différente n'est créé qu'une fois (critique)" do
      post user_registration_url, params: inscription.deep_merge(user: { noms_services: ['', 'technique', 'Technique '] })

      assert_equal %w[Technique], User.find_by!(email: 'jeanne.dupont@exemple.fr').services.map(&:nom)
    end

    test "une inscription sans service n'est pas enregistrée (critique)" do
      assert_no_difference %w[User.count Organisation.count Service.count] do
        post user_registration_url, params: inscription.deep_merge(user: { noms_services: [''] })
      end

      assert_response :unprocessable_content
    end

    test "une inscription dont le nom d'organisation n'est fait que d'espaces n'est pas enregistrée (critique)" do
      assert_no_difference %w[User.count Organisation.count Service.count] do
        post user_registration_url, params: inscription.deep_merge(user: { nom_organisation: '   ' })
      end

      assert_response :unprocessable_content
    end

    # ==================== /TESTS CRITIQUES ====================

    private

    # Ce que poste le formulaire rempli : le champ caché vide de Rails précède les services choisis.
    def inscription
      { user: { prénom: 'Jeanne', nom: 'Dupont', email: 'jeanne.dupont@exemple.fr',
                nom_organisation: 'Mairie de Test', noms_services: ['', 'Technique', 'Voirie'],
                password: 'Motdepasse12!', password_confirmation: 'Motdepasse12!' } }
    end
  end
end
