# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:bond)
    sign_in users(:administrateur_paris)
  end

  # ==== TESTS CRITIQUES : création d'un utilisateur et rattachement au service ====
  # Un compte sans service n'a pas d'organisation : il n'apparaît dans aucune liste
  # (`by_service` joint `user_services`), son email reste pris, et l'invitation qui
  # suit la création échouait en 500. La création doit donc être refusée en bloc.

  ATTRIBUTS_BASE = { nom: 'Nouveau', prénom: 'Venu', email: 'nouveau.venu@example.test' }.freeze

  def créer(connecté: nil, **attributs)
    sign_in connecté if connecté
    post admin_create_new_user_do_url, params: { user: ATTRIBUTS_BASE.merge(attributs) }
    User.find_by(email: ATTRIBUTS_BASE[:email])
  end

  test 'critique : un agent est créé rattaché à son service et invité' do
    assert_emails 1 do
      créé = créer(rôle: 'agent', service_ids: [services(:informatique).id])

      assert_not_nil créé
      assert_equal [services(:informatique)], créé.services.to_a
      assert_equal organisations(:mairie_paris), créé.organisation
      assert_redirected_to user_url(créé)
    end
  end

  # Sentinelle des permits : la création (admin#create_new_user_do) et la modification
  # (users#update) partagent UserParamsPermis. Si quelqu'un redéclare un `user_params`
  # local en oubliant un champ, il disparaît en silence du formulaire — c'est
  # exactement ce qui était arrivé à l'ancienne action create_new_user_do.
  test 'critique : la création accepte tous les champs du formulaire' do
    post admin_create_new_user_do_url, params: {
      user: { nom: 'Complet', prénom: 'Champs', email: 'complet@example.test',
              rôle: 'adhérent', téléphone: '0102030405', memo: 'Note interne',
              address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
              color: '#123456', tag_list: ['Secteur Nord'],
              service_ids: [services(:informatique).id],
              profile_picture: fixture_file_upload('exemple.png', 'image/png') }
    }

    créé = User.find_by(email: 'complet@example.test')
    assert_not_nil créé, "la création a échoué : #{flash[:alert]}"
    assert_equal 'COMPLET', créé.nom
    assert_equal 'Champs', créé.prénom
    assert_equal 'adhérent', créé.rôle
    assert_equal '0102030405', créé.téléphone
    assert_equal 'Note interne', créé.memo
    assert_equal 'Mairie de Paris', créé.address
    assert_equal '#123456', créé.color
    assert_equal ['Secteur Nord'], créé.tag_list
    assert_equal [services(:informatique)], créé.services.to_a
    assert créé.profile_picture.attached?
  end

  test 'critique : aucun compte n’est créé sans service' do
    assert_no_emails do
      assert_no_difference -> { User.count } do
        créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)
      end
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit comporter au moins un service'
  end

  # Rails accompagne tout select `multiple` d'un champ caché vide, pour qu'une
  # sélection entièrement vidée soit transmise. Le serveur reçoit alors `['']`,
  # qui n'est PAS `blank?` : la garde doit dépiler le tableau, pas le tester tel quel.
  test 'critique : une sélection de services vidée ne crée aucun compte' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
            service_ids: [''])
    end

    assert_response :unprocessable_content
  end

  test 'le select des services ne propose aucune option vide' do
    get admin_create_new_user_url

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m]
    assert_no_match(/<option value=""/, select_html.to_s)
  end

  test 'critique : un service d’une autre organisation ne crée aucun compte' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:service_marseille).id])
    end

    assert_response :unprocessable_content
  end

  test 'critique : un agent ne peut pas être créé avec deux services' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'un seul service'
  end

  test 'un adhérent peut être créé avec plusieurs services' do
    créé = créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
                 service_ids: [services(:informatique).id, services(:technique).id])

    assert_not_nil créé
    assert_equal 2, créé.services.count
  end

  # --- Périmètre des services assignables ---

  test 'critique : un manager ne peut rattacher qu’à ses propres services' do
    hors_périmètre = services(:comptabilite) # aucun manager de Paris n'y est rattaché

    assert_no_difference -> { User.count } do
      créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [hors_périmètre.id])
    end

    assert_response :unprocessable_content
  end

  test 'un manager rattache à l’un de ses services' do
    créé = créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [services(:technique).id])

    assert_not_nil créé
    assert_equal [services(:technique)], créé.services.to_a
  end

  test 'critique : un administrateur rattache à n’importe quel service de son organisation et garde la main dessus' do
    hors_de_ses_services = services(:comptabilite)

    créé = créer(rôle: 'agent', service_ids: [hors_de_ses_services.id])

    assert_not_nil créé
    assert_equal [hors_de_ses_services], créé.services.to_a

    # Le compte doit rester accessible : sinon l'administrateur le voit dans la liste
    # sans pouvoir l'ouvrir, le modifier ni relancer son invitation.
    follow_redirect!
    assert_response :success
    assert_nil flash[:alert]

    get edit_user_url(créé)
    assert_response :success
  end

  test 'critique : un administrateur ne touche pas à un utilisateur d’une autre organisation' do
    autre_org = users(:agent_marseille)

    get user_url(autre_org)
    assert_redirected_to root_path

    patch user_url(autre_org), params: { user: { nom: 'FORGE' } }
    assert_redirected_to root_path
    assert_not_equal 'FORGE', autre_org.reload.nom
  end

  # Bornage silencieux : les identifiants hors périmètre sont retirés, les valides gardés.
  test 'un service hors périmètre soumis avec un service valide est ignoré' do
    créé = créer(connecté: users(:hidalgo), rôle: 'adhérent',
                 address: 'Mairie', latitude: 1.0, longitude: 2.0,
                 service_ids: [services(:technique).id, services(:comptabilite).id,
                               services(:service_marseille).id])

    assert_not_nil créé
    assert_equal [services(:technique)], créé.services.to_a
  end

  # --- Modification : le formulaire doit re-proposer l'état courant ---

  test 'critique : en modification, les services actuels sont présélectionnés' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:technique).id]

    get edit_user_url(adhérent)

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m].to_s
    sélectionnés = select_html.scan(/<option selected="selected" value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, sélectionnés.sort
  end

  test 'enregistrer une fiche sans toucher aux services les conserve' do
    agent = users(:bond)
    services_avant = agent.services.ids

    patch user_url(agent), params: { user: { nom: agent.nom, service_ids: services_avant.map(&:to_s) } }

    assert_equal services_avant, agent.reload.services.ids
  end

  # --- Qui peut créer, et avec quel rôle ---

  test 'critique : un agent ne peut pas créer de compte' do
    assert_no_difference -> { User.count } do
      créer(connecté: users(:bond), rôle: 'agent', service_ids: [services(:informatique).id])
    end

    assert_redirected_to root_path
  end

  test 'critique : un adhérent ne peut pas créer de compte' do
    assert_no_difference -> { User.count } do
      créer(connecté: users(:weil), rôle: 'agent', service_ids: [services(:informatique).id])
    end

    assert_redirected_to root_path
  end

  User.rôles.each_key do |rôle|
    test "un administrateur peut créer un #{rôle}" do
      créé = créer(rôle: rôle, service_ids: [services(:informatique).id],
                   address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)

      assert_not_nil créé
      assert_equal rôle, créé.rôle
    end
  end

  test 'critique : un manager ne crée que des agents, quel que soit le rôle demandé' do
    sign_in users(:hidalgo)

    %w[adhérent manager administrateur].each do |demandé|
      post admin_create_new_user_do_url, params: {
        user: { nom: 'Forcé', prénom: 'Agent', email: "force-#{demandé}@example.test",
                rôle: demandé, service_ids: [services(:informatique).id] }
      }

      créé = User.find_by(email: "force-#{demandé}@example.test")
      assert_not_nil créé, "aucun compte créé pour le rôle demandé #{demandé}"
      assert_equal 'agent', créé.rôle
    end
  end

  # --- Mise à jour : le périmètre du manager ne doit rien effacer ---

  test 'un manager qui enregistre une fiche ne perd pas les services hors de son périmètre' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo) # rattaché à service_paris / informatique / technique

    patch user_url(adhérent), params: { user: { nom: adhérent.nom, service_ids: adhérent.service_ids } }

    assert_equal 2, adhérent.reload.services.count
    assert_includes adhérent.services, services(:comptabilite)
  end

  # Un manager ne choisit pas les services d'une fiche existante : le formulaire les
  # renvoie en champs cachés. Il en faut UN PAR SERVICE — un `hidden_field :service_ids`
  # unique sérialise le tableau en une chaîne que `permit(service_ids: [])` rejette.
  test 'critique : en modification, un manager renvoie un champ caché par service' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo)

    get edit_user_url(adhérent)

    assert_select 'select#user_service_ids', { count: 0 }, 'un manager ne réaffecte pas les services'
    valeurs = response.body.scan(/name="user\[service_ids\]\[\]"[^>]*value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, valeurs.sort
  end

  # send_devise_notification trace un MailLog sur l'organisation, dérivée des services.
  # Un compte antérieur à la validation n'en a pas : le mail doit partir quand même.
  test 'critique : une notification Devise sur un compte sans service n’explose pas' do
    orphelin = User.new(nom: 'Orphelin', prénom: 'Sans', email: 'orphelin@example.test',
                        rôle: 'adhérent', password: 'qtDug$d843sqACz?V')
    orphelin.save(validate: false)

    assert_nil orphelin.organisation

    assert_emails 1 do
      assert_no_difference -> { MailLog.count } do
        orphelin.send_reset_password_instructions
      end
    end
  end

  # --- Formulaire ---

  test 'un manager ne se voit proposer que ses propres services' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal users(:hidalgo).services.ids.sort, proposés.sort
  end

  test 'un administrateur se voit proposer tous les services de son organisation' do
    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal organisations(:mairie_paris).services.ids.sort, proposés.sort
  end

  test 'aucun service d’une autre organisation n’est proposé' do
    get admin_create_new_user_url

    assert_not_includes ids_du_select_services(response.body), services(:service_marseille).id
  end

  test 'un manager mono-service voit son service déjà sélectionné' do
    mono = users(:michael_jackson) # manager, uniquement service_marseille2
    sign_in mono

    get admin_create_new_user_url

    assert_select "select#user_service_ids option[selected][value=?]", services(:service_marseille2).id.to_s
  end

  test 'un manager multi-services n’a aucun service présélectionné' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    assert_select 'select#user_service_ids option[selected]', count: 0
  end

  def ids_du_select_services(body)
    select_html = body[/<select[^>]*id="user_service_ids".*?<\/select>/m].to_s
    select_html.scan(/<option value="(\d+)"/).flatten.map(&:to_i)
  end

  # Index
  test 'should get index' do
    get users_url
    assert_response :success
  end

  # --- Pré-filtrage par service de l'index --------------------------------
  # Le setup signe administrateur_paris (services : service_paris / informatique /
  # technique).

  test 'index : un administrateur ne voit que ses services par défaut' do
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un utilisateur hors des services de l\'administrateur ne doit pas apparaître par défaut'
  end

  test "index : un administrateur peut filtrer sur un autre service de son organisation" do
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { minimum: 1 },
                  "l'administrateur peut voir les utilisateurs d'un service de son organisation hors des siens"
  end

  test "index : le menu services propose toute l'organisation à un administrateur" do
    get users_url

    assert_response :success
    assert_select "select[name='services[]'] option", { text: 'Comptabilité' }
  end

  test "index : un manager ne peut pas forger un service hors de son périmètre" do
    sign_in users(:hidalgo) # manager : service_paris / informatique / technique
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un manager ne doit pas voir un service hors de son périmètre via un param forgé'
    assert_select "select[name='services[]'] option", { text: 'Comptabilité', count: 0 }
  end

  test 'should get index with export xls' do
    get users_url,  params: {
      format: :xls
    }

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

  test 'should get index with param search' do
    get users_url(search: 'tonte')
    assert_response :success
  end

  test 'should get index with param rôle' do
    get users_url(rôle: 'agent')
    assert_response :success
  end

  test 'should get index with param absent' do
    get users_url(absent: true)
    assert_response :success
  end

  test 'should get new' do
    get admin_create_new_user_url
    assert_response :success
  end

  test 'should create user' do
    assert_difference('User.count') do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: 'Foo',
          prénom: 'Bar',
          email: 'email@example.com',
          password: '0DcPIZIq0+f5SvCf',
          rôle: 'agent',
          organisation: organisations(:mairie_paris),
          service_ids: [services(:service_paris).id]
        }
      }
    end

    assert_redirected_to user_url(User.last)
  end

  # Show
  test 'should show user' do
    get user_url(@user)
    assert_response :success
  end

  test 'should show adherent user (rend la section Cotations)' do
    get user_url(users(:weil))
    assert_response :success
  end

  test 'should get edit' do
    get edit_user_url(@user)
    assert_response :success
  end

  test 'should update user' do
    patch user_url(@user), params: {
      user: {
        email: @user.email,
        password: '0DcPIZIq0+f5SvCf',
        rôle: @user.rôle,
        organisation: @user.organisation
      }
    }
    assert_redirected_to user_url(@user)
  end

  test 'should destroy user' do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end

  # Agent calendrier
  test 'should get agent_calendrier' do
    get agent_calendrier_users_url
    assert_response :success
  end

  test 'should get agent_calendrier with param search' do
    get agent_calendrier_users_url(search: 'algo')
    assert_response :success
  end

  test 'should get import' do
    get import_users_url
    assert_response :success
  end

  # Import_do
  test 'should no import without param upload' do
    get import_do_users_url
    assert_redirected_to root_path
  end

  test 'should no import with param upload empty' do
    post import_do_users_url(upload: '')
    assert_redirected_to import_users_url
  end

  test 'should create agent as a manager' do
    assert_difference('User.count', 1) do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: 'Foo',
          prénom: 'Bar',
          email: 'email@example.com',
          password: '0DcPIZIq0+f5SvCf',
          rôle: 'agent',
          organisation: organisations(:mairie_paris),
          service_ids: [services(:service_paris).id]
        }
      }
    end

    assert_redirected_to user_url(User.last)
  end

  test "should'nt create manager as a manager (forced into agent)" do
    sign_in users(:hidalgo)

    unauthorized_role = 'manager'

    assert_difference('User.count', 1) do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: 'Foo',
          prénom: 'Bar',
          email: 'email@example.com',
          password: '0DcPIZIq0+f5SvCf',
          rôle: unauthorized_role,
          organisation: organisations(:mairie_paris),
          service_ids: [services(:service_paris).id]
        }
      }
    end

    new_user = User.last

    assert_equal 'agent', new_user.rôle, "Le rôle est censé être agent si c'est un manager qui le créé"
    assert_not_equal unauthorized_role, new_user.rôle
  end

  test "should'nt create administrateur as a manager (forced into agent)" do
    sign_in users(:hidalgo)

    unauthorized_role = 'administrateur'

    assert_difference('User.count', 1) do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: 'Foo',
          prénom: 'Bar',
          email: 'email@example.com',
          password: '0DcPIZIq0+f5SvCf',
          rôle: unauthorized_role,
          organisation: organisations(:mairie_paris),
          service_ids: [services(:service_paris).id]
        }
      }
    end

    new_user = User.last

    assert_equal 'agent', new_user.rôle, "Le rôle est censé être agent si c'est un manager qui le créé"
    assert_not_equal unauthorized_role, new_user.rôle
  end

  # --- show : filtrage de l'historique ---

  # Les audits d'un autre auditable que User (ici une absence, auditée
  # `associated_with: :user`) traversent le filtre sans être écartés.
  test 'show conserve les audits associés qui ne portent pas sur le compte' do
    Absence.create!(user: @user, du: Date.new(2030, 7, 1), au: Date.new(2030, 7, 2), motif: :formation)

    get user_url(@user)

    assert_response :success
    assert assigns(:audits).any? { |audit| audit.auditable_type == 'Absence' }
  end

  # --- create : branches d'échec ---

  test 'create invalide réaffiche le formulaire en 422' do
    assert_no_difference('User.count') do
      post admin_create_new_user_do_url, params: { user: { nom: 'SANS', prénom: 'Email', email: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'create invalide en JSON renvoie les erreurs' do
    post admin_create_new_user_do_url,
         params: { user: { nom: 'SANS', prénom: 'Email', email: '',
                           service_ids: [services(:informatique).id] } },
         as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end

  # --- update : branches d'échec ---

  test 'update invalide réaffiche le formulaire en 422' do
    patch user_url(@user), params: { user: { email: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @user.reload.email
  end

  test 'update invalide en JSON renvoie les erreurs' do
    patch user_url(@user), params: { user: { email: '' } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end

  test 'update invalide en turbo_stream remplace le formulaire utilisateur' do
    patch user_url(@user), params: { user: { email: '' } }, as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  test 'update invalide depuis la modale d\'absence remplace le formulaire d\'absence' do
    patch user_url(@user),
          params: { user: { absences_attributes: { '0' => { du: '2030-08-10', au: '2030-08-01',
                                                            motif: 'formation' } } },
                    from_absence_modal: '1' },
          as: :turbo_stream

    assert_response :success
    assert_match(/absence_form/, response.body)
  end

  test 'un agent ne peut pas se créer une absence depuis son propre profil' do
    agent = users(:bond)
    sign_in agent

    assert_no_difference('Absence.count') do
      patch user_url(agent),
            params: { user: { absences_attributes: { '0' => { du: '2030-09-10', au: '2030-09-10',
                                                              motif: 'formation' } } } }
    end
  end

  test 'un agent ne peut pas supprimer une absence via les paramètres de son profil' do
    agent = users(:bond)
    absence = absences(:one)
    sign_in agent

    assert_no_difference('Absence.count') do
      patch user_url(agent),
            params: { user: { absences_attributes: { '0' => { id: absence.id, _destroy: '1' } } } }
    end
  end

  # --- inviter / mot de passe / réactivation ---

  test 'inviter renvoie le lien d\'accès' do
    post inviter_user_url(@user)

    assert_redirected_to user_path(@user)
    assert_match(/renvoyé avec succès/i, flash[:notice].to_s)
  end

  # `edit_password?`/`update_password?` = `is_myself?` : seul le titulaire du
  # compte peut changer son mot de passe.
  test 'should get edit_password' do
    sign_in @user
    get edit_password_user_url(@user)

    assert_response :success
  end

  test 'update_password enregistre un nouveau mot de passe' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'Nouveau-MotDePasse-42!' } }

    assert_redirected_to user_url(@user)
    assert @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'update_password avec une confirmation qui diffère est refusé en 422' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'autre-chose' } }

    assert_response :unprocessable_content
    assert_not @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'update_password en JSON renvoie les erreurs' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'court', password_confirmation: 'court' } },
          as: :json

    assert_response :unprocessable_content
  end

  test 'reactivate réhabilite un compte désactivé' do
    desactive = users(:agent_whatsapp) # service_paris, donc dans le périmètre de l'administrateur
    desactive.discard

    patch reactivate_user_url(desactive)

    assert_redirected_to users_path
    assert_not desactive.reload.discarded?
  end

  test 'reactivate échoue proprement si le compte est déjà actif' do
    patch reactivate_user_url(@user)

    assert_redirected_to users_path(discarded: true)
    assert_match(/Impossible de réactiver/i, flash[:alert].to_s)
  end

  # test "should import xls with param upload" do
  #   headers = ["Nom", "Prénom", "Email", "Téléphone", "Service", "Mémo"]
  #   data = [
  #     headers,
  #     ["DUCHAMP", "Jean", "jean@example.com", "0601020304", "Technique", "Note perso"]
  #   ]

  #   file_path = create_xls_file('test_agents.xls', data)

  #   assert_difference 'User.count', 1 do
  #     post import_do_users_url, params: {
  #       upload: fixture_file_upload(file_path, 'application/vnd.ms-excel')
  #     }
  #   end

  #   File.delete(file_path)

  #   assert_redirected_to agents_path
  # end

  # def create_xls_file(filename, rows)
  #   book = Spreadsheet::Workbook.new
  #   sheet = book.create_worksheet(name: "Import")

  #   # Ajout des données (rows est un tableau de tableaux)
  #   rows.each_with_index do |row_data, index|
  #     sheet.row(index).replace(row_data)
  #   end

  #   # Sauvegarde physique du fichier
  #   path = Rails.root.join('tmp', filename)
  #   book.write(path)
  #   path
  # end
end
