# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @user = users(:bond)
    sign_in users(:administrateur_paris)
  end

  # Un compte sans service n'a pas d'organisation : il n'apparaît dans aucune liste
  # (`by_service` joint `user_services`), son email reste pris, et l'invitation qui
  # suit la création échouait en 500. La création doit donc être refusée en bloc.

  # Champs minimaux d'une création, complétés par chaque test.
  ATTRIBUTS_BASE = { nom: 'Nouveau', prénom: 'Venu', email: 'nouveau.venu@example.test' }.freeze

  # Index
  test 'index : sans paramètre → la page répond' do
    get users_url
    assert_response :success
  end

  test 'index : recherche → seulement les utilisateurs correspondants' do
    get users_url(search: 'tonte')
    assert_response :success
  end

  test 'index : filtre rôle → seulement les utilisateurs de ce rôle' do
    get users_url(rôle: 'agent')
    assert_response :success
  end

  test 'index : filtre absent → seulement les utilisateurs absents' do
    get users_url(absent: true)
    assert_response :success
  end

  test 'index : un administrateur ne voit que ses services par défaut' do
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un utilisateur hors des services de l\'administrateur ne doit pas apparaître par défaut'
  end

  test 'index : un administrateur peut filtrer sur un autre service de son organisation' do
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

  test 'index : un manager ne peut pas forger un service hors de son périmètre' do
    sign_in users(:hidalgo) # manager : service_paris / informatique / technique
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un manager ne doit pas voir un service hors de son périmètre via un param forgé'
    assert_select "select[name='services[]'] option", { text: 'Comptabilité', count: 0 }
  end

  test 'index : format xls → un classeur Excel est téléchargé' do
    get users_url,  params: {
      format: :xls
    }

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

  # Show
  test 'show : un utilisateur de son organisation → la page répond' do
    get user_url(@user)
    assert_response :success
  end

  test 'show : un adhérent → la section Cotations est rendue' do
    get user_url(users(:weil))
    assert_response :success
  end

  # `associated_with: :user`) traversent le filtre sans être écartés.
  test 'show : conserve les audits associés qui ne portent pas sur le compte' do
    Absence.create!(user: @user, du: Date.new(2030, 7, 1), au: Date.new(2030, 7, 2), motif: :formation)

    get user_url(@user)

    assert_response :success
    assert assigns(:audits).any? { |audit| audit.auditable_type == 'Absence' }
  end

  test 'show : la fiche d un utilisateur affiche ses mots clés' do
    agent = users(:bond)
    agent.update!(tag_list: 'secteur-nord')

    get user_url(agent)

    assert_response :success
    assert_match 'secteur-nord', response.body
  end

  test 'create_new_user : le select des services ne propose aucune option vide' do
    get admin_create_new_user_url

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m]
    assert_no_match(/<option value=""/, select_html.to_s)
  end

  # ==================== TESTS CRITIQUES ====================

  test 'create_new_user : le rôle est le premier champ du formulaire (critique)' do
    get admin_create_new_user_url

    champs = response.body.scan(/(?:name|id)="user(?:\[)?(rôle|nom)/).flatten
    assert_equal 'rôle', champs.first, 'le rôle doit être demandé avant le nom'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'create_new_user : un manager ne se voit proposer que ses propres services' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal users(:hidalgo).services.ids.sort, proposés.sort
  end

  test 'create_new_user : un administrateur se voit proposer tous les services de son organisation' do
    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal organisations(:mairie_paris).services.ids.sort, proposés.sort
  end

  test 'create_new_user : aucun service d’une autre organisation n’est proposé' do
    get admin_create_new_user_url

    assert_not_includes ids_du_select_services(response.body), services(:service_marseille).id
  end

  test 'create_new_user : un manager mono-service voit son service déjà sélectionné' do
    mono = users(:michael_jackson) # manager, uniquement service_marseille2
    sign_in mono

    get admin_create_new_user_url

    assert_select "select#user_service_ids option[selected][value=?]", services(:service_marseille2).id.to_s
  end

  test 'create_new_user : un manager multi-services n’a aucun service présélectionné' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    assert_select 'select#user_service_ids option[selected]', count: 0
  end

  test 'create_new_user : le champ Équipe accepte la création d’un mot clé' do
    get admin_create_new_user_url

    assert_select 'select#user_tag_list[data-addable=?]', 'true'
  end

  test 'create_new_user : sans paramètre → la page répond' do
    get admin_create_new_user_url

    assert_response :success
  end

  test 'create_new_user : le formulaire s’ouvre sur le rôle agent' do
    get admin_create_new_user_url

    assert_equal 'agent', assigns(:user).rôle
  end

  # l'inscription publique et aucun compte n'est créé.
  test 'create_new_user : le formulaire poste sur le chemin dédié, pas sur POST /users' do
    get admin_create_new_user_url

    assert_select 'form[action=?][method=?]', admin_create_new_user_do_path, 'post'
  end

  # ==================== TESTS CRITIQUES ====================

  test 'create_new_user_do : un agent est créé rattaché à son service et invité (critique)' do
    assert_emails 1 do
      créé = créer(rôle: 'agent', service_ids: [services(:informatique).id])

      assert_not_nil créé
      assert_equal [services(:informatique)], créé.services.to_a
      assert_equal organisations(:mairie_paris), créé.organisation
      assert_redirected_to user_url(créé)
    end
  end

  # exactement ce qui était arrivé à l'ancienne action create_new_user_do.
  test 'create_new_user_do : tous les champs du formulaire sont acceptés (critique)' do
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

  test 'create_new_user_do : sans service → aucun compte créé (critique)' do
    assert_no_emails do
      assert_no_difference -> { User.count } do
        créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)
      end
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit comporter au moins un service'
  end

  # qui n'est PAS `blank?` : la garde doit dépiler le tableau, pas le tester tel quel.
  test 'create_new_user_do : sélection de services vidée → aucun compte créé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
            service_ids: [''])
    end

    assert_response :unprocessable_content
  end

  test 'create_new_user_do : un service d’une autre organisation → aucun compte créé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:service_marseille).id])
    end

    assert_response :unprocessable_content
  end

  test 'create_new_user_do : un agent avec deux services → refusé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'un seul service'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'create_new_user_do : un adhérent peut être créé avec plusieurs services' do
    créé = créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
                 service_ids: [services(:informatique).id, services(:technique).id])

    assert_not_nil créé
    assert_equal 2, créé.services.count
  end

  # ==================== TESTS CRITIQUES ====================

  test 'create_new_user_do : un manager ne rattache qu’à ses propres services (critique)' do
    hors_périmètre = services(:comptabilite) # aucun manager de Paris n'y est rattaché

    assert_no_difference -> { User.count } do
      créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [hors_périmètre.id])
    end

    assert_response :unprocessable_content
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'create_new_user_do : un manager rattache à l’un de ses services' do
    créé = créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [services(:technique).id])

    assert_not_nil créé
    assert_equal [services(:technique)], créé.services.to_a
  end

  # ==================== TESTS CRITIQUES ====================

  test 'create_new_user_do : un administrateur rattache à tout service de son organisation et garde la main (critique)' do
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

  # ==================== /TESTS CRITIQUES ====================

  # Bornage silencieux : les identifiants hors périmètre sont retirés, les valides gardés.
  test 'create_new_user_do : un service hors périmètre soumis avec un service valide est ignoré' do
    créé = créer(connecté: users(:hidalgo), rôle: 'adhérent',
                 address: 'Mairie', latitude: 1.0, longitude: 2.0,
                 service_ids: [services(:technique).id, services(:comptabilite).id,
                               services(:service_marseille).id])

    assert_not_nil créé
    assert_equal [services(:technique)], créé.services.to_a
  end

  User.rôles.each_key do |rôle|
    test "un administrateur peut créer un #{rôle}" do
      créé = créer(rôle: rôle, service_ids: [services(:informatique).id],
                   address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)

      assert_not_nil créé
      assert_equal rôle, créé.rôle
    end
  end

  # ==================== TESTS CRITIQUES ====================

  test 'create_new_user_do : un manager ne crée que des agents, quel que soit le rôle demandé (critique)' do
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

  # Un compte antérieur à la validation n'en a pas : le mail doit partir quand même.
  test 'create_new_user_do : une notification Devise sur un compte sans service n’explose pas (critique)' do
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

  # Un compte dont le mot de passe est perdu n'a pas d'autre porte d'entrée que
  # ce mail : sans lui, son titulaire est enfermé dehors.
  test 'mot de passe oublié : une adresse connue reçoit son mail de réinitialisation (critique)' do
    # Doit etre déconnecté
    sign_out @user

    assert_emails 1 do
      post user_password_url, params: { user: { email: @user.email } }
    end

    assert_equal [@user.email], ActionMailer::Base.deliveries.last.to
    assert @user.reload.reset_password_token, "aucun jeton de réinitialisation n'a été posé"
  end

  # `config.paranoid = true` : le message est le même qu'avec une adresse connue,
  # pour qu'on ne puisse pas deviner qui a un compte. Seul l'envoi les distingue.
  test 'mot de passe oublié : une adresse inconnue ne déclenche aucun mail (critique)' do
    # Doit etre déconnecté
    sign_out @user

    assert_no_emails do
      post user_password_url, params: { user: { email: 'personne@example.test' } }
    end

    assert_redirected_to new_user_session_path
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'create_new_user_do : paramètres invalides → formulaire réaffiché en 422' do
    assert_no_difference('User.count') do
      post admin_create_new_user_do_url, params: { user: { nom: 'SANS', prénom: 'Email', email: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'edit : un utilisateur de son organisation → la page répond' do
    get edit_user_url(@user)
    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'edit : les services actuels sont présélectionnés (critique)' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:technique).id]

    get edit_user_url(adhérent)

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m].to_s
    sélectionnés = select_html.scan(/<option selected="selected" value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, sélectionnés.sort
  end

  # unique sérialise le tableau en une chaîne que `permit(service_ids: [])` rejette.
  test 'edit : un manager renvoie un champ caché par service (critique)' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo)

    get edit_user_url(adhérent)

    assert_select 'select#user_service_ids', { count: 0 }, 'un manager ne réaffecte pas les services'
    valeurs = response.body.scan(/name="user\[service_ids\]\[\]"[^>]*value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, valeurs.sort
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'edit : le formulaire de modification propose les mots clés déjà utilisés' do
    users(:bond).update!(tag_list: 'secteur-nord')

    get edit_user_url(users(:martin_technique_paris))

    assert_response :success
    assert_includes assigns(:users_tags).map(&:name), 'secteur-nord'
  end

  # ==================== TESTS CRITIQUES ====================

  test 'edit : les mots clés d’une autre organisation ne sont pas proposés (critique)' do
    users(:nettoyeur_marseille).update!(tag_list: 'secret-marseille')

    get edit_user_url(users(:martin_technique_paris))

    assert_response :success
    assert_not_includes assigns(:users_tags).map(&:name), 'secret-marseille'
  end

  # ==================== /TESTS CRITIQUES ====================

  test "update : paramètres valides → l'utilisateur est modifié" do
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

  # ==================== TESTS CRITIQUES ====================

  test 'update : par un agent sur lui-même, rôle administrateur soumis → rôle inchangé (critique)' do
    bond = users(:bond)
    sign_in bond

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'administrateur' } }

    assert bond.reload.agent?
  end

  test 'update : par un manager, rôle manager soumis sur un agent → rôle inchangé (critique)' do
    sign_in users(:hidalgo)
    bond = users(:bond)

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'manager' } }

    assert bond.reload.agent?
  end

  test 'update : service_ids d’une autre organisation soumis → services inchangés (critique)' do
    sign_in users(:hidalgo)
    bond = users(:bond)
    services_avant = bond.services.sort_by(&:id)

    patch user_url(bond), params: { user: { nom: bond.nom, service_ids: [services(:service_marseille).id] } }

    assert_not_includes bond.reload.services, services(:service_marseille)
    assert_equal services_avant, bond.services.sort_by(&:id)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'update : invalide réaffiche le formulaire en 422' do
    patch user_url(@user), params: { user: { email: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @user.reload.email
  end

  # les laisserait invisibles. Seule la modale d'absence reste en turbo-stream.
  test 'update : invalide réaffiche le formulaire complet en HTML, pas en turbo-stream' do
    patch user_url(@user), params: { user: { email: '' } }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_no_match(/turbo-stream/, response.body)
    assert_select "form##{ActionView::RecordIdentifier.dom_id(@user)}"
    assert_select 'select#user_service_ids[data-controller~=?]', 'slim-select'
  end

  test "update : invalide depuis la modale d\'absence → le formulaire d\'absence est remplacé" do
    patch user_url(@user),
          params: { user: { absences_attributes: { '0' => { du: '2030-08-10', au: '2030-08-01',
                                                            motif: 'formation' } } },
                    from_absence_modal: '1' },
          as: :turbo_stream

    assert_response :success
    assert_match(/absence_form/, response.body)
  end

  test 'update : un refus de validation ne laisse pas les services modifiés en base' do
    agent = users(:bond)
    services_avant = agent.services.ids
    ajout = services(:service_paris).id

    patch user_url(agent), params: {
      user: { nom: agent.nom, service_ids: (services_avant + [ajout]).map(&:to_s) }
    }

    assert_response :unprocessable_content
    assert_equal services_avant, agent.reload.services.ids
  end

  test 'update : changer le service d un agent est enregistré' do
    agent = users(:bond)
    nouveau = services(:service_paris)

    patch user_url(agent), params: { user: { nom: agent.nom, service_ids: ['', nouveau.id.to_s] } }

    assert_equal [nouveau.id], agent.reload.services.ids
  end

  test 'update : enregistrer une fiche sans toucher aux services les conserve' do
    agent = users(:bond)
    services_avant = agent.services.ids

    patch user_url(agent), params: { user: { nom: agent.nom, service_ids: services_avant.map(&:to_s) } }

    assert_equal services_avant, agent.reload.services.ids
  end

  test 'update : un manager qui enregistre une fiche ne perd pas les services hors de son périmètre' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo) # rattaché à service_paris / informatique / technique

    patch user_url(adhérent), params: { user: { nom: adhérent.nom, service_ids: adhérent.service_ids } }

    assert_equal 2, adhérent.reload.services.count
    assert_includes adhérent.services, services(:comptabilite)
  end

  test 'update : un agent ne peut pas se créer une absence depuis son propre profil' do
    agent = users(:bond)
    sign_in agent

    assert_no_difference('Absence.count') do
      patch user_url(agent),
            params: { user: { absences_attributes: { '0' => { du: '2030-09-10', au: '2030-09-10',
                                                              motif: 'formation' } } } }
    end
  end

  test 'update : un agent ne peut pas supprimer une absence via les paramètres de son profil' do
    agent = users(:bond)
    absence = absences(:one)
    sign_in agent

    assert_no_difference('Absence.count') do
      patch user_url(agent),
            params: { user: { absences_attributes: { '0' => { id: absence.id, _destroy: '1' } } } }
    end
  end

  test 'update : les mots clés d un utilisateur sont modifiables depuis sa fiche' do
    agent = users(:bond)

    patch user_url(agent), params: { user: { nom: agent.nom, tag_list: ['', 'secteur-nord', 'astreinte'] } }

    assert_equal %w[secteur-nord astreinte], agent.reload.tag_list
  end

  test 'update : vider le champ Mots clés les retire vraiment' do
    agent = users(:bond)
    agent.update!(tag_list: 'secteur-nord')

    patch user_url(agent), params: { user: { nom: agent.nom, tag_list: [''] } }

    assert_empty agent.reload.tag_list
  end

  # ==================== TESTS CRITIQUES ====================

  test 'update : un administrateur ne touche pas à un utilisateur d’une autre organisation (critique)' do
    autre_org = users(:agent_marseille)

    get user_url(autre_org)
    assert_redirected_to root_path

    patch user_url(autre_org), params: { user: { nom: 'FORGE' } }
    assert_redirected_to root_path
    assert_not_equal 'FORGE', autre_org.reload.nom
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'destroy : un utilisateur de son organisation → il est désactivé' do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end

  # Agent calendrier
  test 'agent_calendrier : sans paramètre → la page répond' do
    get agent_calendrier_users_url
    assert_response :success
  end

  test 'agent_calendrier : recherche → seulement les agents correspondants' do
    get agent_calendrier_users_url(search: 'algo')
    assert_response :success
  end

  test "inviter : le lien d'accès est renvoyé" do
    post inviter_user_url(@user)

    assert_redirected_to user_path(@user)
    assert_match(/renvoyé avec succès/i, flash[:notice].to_s)
  end

  # compte peut changer son mot de passe.
  test 'edit_password : sans paramètre → la page répond' do
    sign_in @user
    get edit_password_user_url(@user)

    assert_response :success
  end

  test 'update_password : enregistre un nouveau mot de passe' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'Nouveau-MotDePasse-42!' } }

    assert_redirected_to user_url(@user)
    assert @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'update_password : avec une confirmation qui diffère est refusé en 422' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'autre-chose' } }

    assert_response :unprocessable_content
    assert_not @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'reactivate : réhabilite un compte désactivé' do
    desactive = users(:agent_whatsapp) # service_paris, donc dans le périmètre de l'administrateur
    desactive.discard

    patch reactivate_user_url(desactive)

    assert_redirected_to users_path
    assert_not desactive.reload.discarded?
  end

  test 'reactivate : échoue proprement si le compte est déjà actif' do
    patch reactivate_user_url(@user)

    assert_redirected_to users_path(discarded: true)
    assert_match(/Impossible de réactiver/i, flash[:alert].to_s)
  end

  # TODO: A changer par un assigns ou split
  def ids_du_select_services(body)
    select_html = body[/<select[^>]*id="user_service_ids".*?<\/select>/m].to_s
    select_html.scan(/<option value="(\d+)"/).flatten.map(&:to_i)
  end

  private

  def créer(connecté: nil, **attributs)
    sign_in connecté if connecté
    post admin_create_new_user_do_url, params: { user: ATTRIBUTS_BASE.merge(attributs) }
    User.find_by(email: ATTRIBUTS_BASE[:email])
  end
end
