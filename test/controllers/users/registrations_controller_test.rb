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

    test "le formulaire d'inscription propose un nom d'organisation EPCI suivi d'un numéro à cinq chiffres" do
      get new_user_registration_url

      assert_dom 'input[name=?]', 'user[nom_organisation]' do |champ|
        assert_match(/\AEPCI#[1-9]\d{4}\z/, champ.first['value'])
      end
    end

    test "le formulaire d'inscription propose le seul service Technique" do
      get new_user_registration_url

      assert_dom 'select[name=?] option[selected]', 'user[noms_services][]', count: 1, text: 'Technique'
    end

    test "une inscription mène à la page de connexion en annonçant le mail de confirmation" do
      post user_registration_url, params: inscription

      assert_redirected_to new_user_session_url
      assert_equal 'Un message avec un lien de confirmation vous a été envoyé par mail. ' \
                   'Veuillez suivre ce lien pour activer votre compte.', flash[:notice]
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

    test "une inscription envoie à l'inscrit le lien de confirmation de son compte, qui reste à confirmer" do
      assert_emails 1 do
        post user_registration_url, params: inscription
      end

      inscrit = User.find_by!(email: 'jeanne.dupont@exemple.fr')
      mail = ActionMailer::Base.deliveries.last
      assert_equal [inscrit.email], mail.to
      assert_includes mail.body.to_s, "confirmation_token=#{inscrit.confirmation_token}"
      assert_not inscrit.confirmed?
    end

    test "le mail log du mail de confirmation est rattaché à l'organisation créée à l'inscription (critique)" do
      post user_registration_url, params: inscription

      inscrit = User.find_by!(email: 'jeanne.dupont@exemple.fr')
      assert_equal [inscrit.organisation], MailLog.where(to: inscrit.email).map(&:organisation)
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

    test 'une inscription ne met aucun mail de bienvenue en file avant la confirmation du compte' do
      assert_no_enqueued_jobs only: WelcomeInscriptionNotificationJob do
        post user_registration_url, params: inscription
      end
    end

    test "une inscription refusée laisse vide le nom d'organisation que l'inscrit a effacé" do
      post user_registration_url, params: inscription.deep_merge(user: { nom_organisation: '' })

      assert_dom 'input[name=?][value=?]', 'user[nom_organisation]', ''
    end

    test "une inscription refusée ne repropose pas le service Technique que l'inscrit a retiré" do
      post user_registration_url, params: inscription.deep_merge(user: { noms_services: [''] })

      assert_dom 'select[name=?] option[selected]', 'user[noms_services][]', count: 0
    end

    test 'un administrateur désactive son compte' do
      administrateur = users(:administrateur_paris)
      sign_in administrateur

      delete user_registration_url

      assert_redirected_to new_user_session_url
      assert_equal 'Au revoir ! Votre compte a bien été désactivé. Nous espérons vous revoir bientôt.', flash[:notice]
      assert administrateur.reload.discarded?
    end

    test 'le dernier administrateur d’une organisation ne peut pas désactiver son compte' do
      dernier_administrateur = users(:administrateur_seul)
      sign_in dernier_administrateur

      delete user_registration_url

      assert_redirected_to root_path
      assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
      assert_not dernier_administrateur.reload.discarded?
    end

    test 'un manager ne peut pas désactiver son compte' do
      manager = users(:hidalgo)
      sign_in manager

      delete user_registration_url

      assert_redirected_to root_path
      assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
      assert_not manager.reload.discarded?
    end

    test "la désactivation du compte est introuvable hors de l'instance de démonstration" do
      ENV['APP_INSTANCE'] = 'production'
      administrateur = users(:administrateur_paris)
      sign_in administrateur

      delete user_registration_url

      assert_response :not_found
      assert_not administrateur.reload.discarded?
    end

    private

    # Ce que poste le formulaire rempli : le champ caché vide de Rails précède les services choisis.
    def inscription
      { user: { prénom: 'Jeanne', nom: 'Dupont', email: 'jeanne.dupont@exemple.fr',
                nom_organisation: 'Mairie de Test', noms_services: ['', 'Technique', 'Voirie'],
                password: 'Motdepasse12!', password_confirmation: 'Motdepasse12!' } }
    end
  end
end
