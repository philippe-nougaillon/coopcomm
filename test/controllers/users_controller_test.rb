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
  test 'la liste des utilisateurs est affichée avec succès' do
    get users_url
    assert_response :success
  end

  test 'la liste des utilisateurs filtrée par une recherche est affichée avec succès' do
    get users_url(search: 'tonte')
    assert_response :success
  end

  test 'la liste des utilisateurs filtrée par rôle est affichée avec succès' do
    get users_url(rôle: 'agent')
    assert_response :success
  end

  test 'la liste des utilisateurs filtrée sur les absents est affichée avec succès' do
    get users_url(absent: true)
    assert_response :success
  end

  test 'un administrateur ne voit par défaut que les utilisateurs de ses services' do
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un utilisateur hors des services de l\'administrateur ne doit pas apparaître par défaut'
  end

  test 'un administrateur peut filtrer la liste des utilisateurs sur un autre service de son organisation' do
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { minimum: 1 },
                  "l'administrateur peut voir les utilisateurs d'un service de son organisation hors des siens"
  end

  test 'le filtre par service propose à un administrateur tous les services de l’organisation' do
    get users_url

    assert_response :success
    assert_select "select[name='services[]'] option", { text: 'Comptabilité' }
  end

  test 'un manager ne peut pas filtrer la liste des utilisateurs sur un service hors de son périmètre' do
    sign_in users(:hidalgo) # manager : service_paris / informatique / technique
    hors_perimetre = users(:john_wick) # service comptabilite

    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", user_path(hors_perimetre), { count: 0 },
                  'un manager ne doit pas voir un service hors de son périmètre via un param forgé'
    assert_select "select[name='services[]'] option", { text: 'Comptabilité', count: 0 }
  end

  test 'la liste des utilisateurs est exportée en classeur Excel' do
    get users_url,  params: {
      format: :xls
    }

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

  # Show
  test 'un utilisateur est affiché avec succès' do
    get user_url(@user)
    assert_response :success
  end

  test 'la fiche d’un adhérent est affichée avec succès' do
    get user_url(users(:weil))
    assert_response :success
  end

  # `associated_with: :user`) traversent le filtre sans être écartés.
  test 'la fiche d’un utilisateur conserve les audits associés qui ne portent pas sur le compte' do
    Absence.create!(user: @user, du: Date.new(2030, 7, 1), au: Date.new(2030, 7, 2), motif: :formation)

    get user_url(@user)

    assert_response :success
    assert assigns(:audits).any? { |audit| audit.auditable_type == 'Absence' }
  end

  test 'la fiche d’un utilisateur affiche ses mots clés' do
    agent = users(:bond)
    agent.update!(tag_list: 'secteur-nord')

    get user_url(agent)

    assert_response :success
    assert_match 'secteur-nord', response.body
  end

  test 'la liste des services du formulaire de création ne propose aucune option vide' do
    get admin_create_new_user_url

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m]
    assert_no_match(/<option value=""/, select_html.to_s)
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le rôle est le premier champ du formulaire de création (critique)' do
    get admin_create_new_user_url

    champs = response.body.scan(/(?:name|id)="user(?:\[)?(rôle|nom)/).flatten
    assert_equal 'rôle', champs.first, 'le rôle doit être demandé avant le nom'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le formulaire de création ne propose à un manager que ses propres services' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal users(:hidalgo).services.ids.sort, proposés.sort
  end

  test 'le formulaire de création propose à un administrateur tous les services de son organisation' do
    get admin_create_new_user_url

    proposés = ids_du_select_services(response.body)
    assert_equal organisations(:mairie_paris).services.ids.sort, proposés.sort
  end

  test 'le formulaire de création ne propose aucun service d’une autre organisation' do
    get admin_create_new_user_url

    assert_not_includes ids_du_select_services(response.body), services(:service_marseille).id
  end

  test 'le formulaire de création présélectionne le service d’un manager mono-service' do
    mono = users(:michael_jackson) # manager, uniquement service_marseille2
    sign_in mono

    get admin_create_new_user_url

    assert_select "select#user_service_ids option[selected][value=?]", services(:service_marseille2).id.to_s
  end

  test 'le formulaire de création ne présélectionne aucun service pour un manager multi-services' do
    sign_in users(:hidalgo)

    get admin_create_new_user_url

    assert_select 'select#user_service_ids option[selected]', count: 0
  end

  test 'le champ Équipe du formulaire de création accepte la création d’un mot clé' do
    get admin_create_new_user_url

    assert_select 'select#user_tag_list[data-addable=?]', 'true'
  end

  test 'le formulaire de création est affiché avec succès' do
    get admin_create_new_user_url

    assert_response :success
  end

  test 'le formulaire de création s’ouvre sur le rôle agent' do
    get admin_create_new_user_url

    assert_equal 'agent', assigns(:user).rôle
  end

  # l'inscription publique et aucun compte n'est créé.
  test 'le formulaire de création poste sur le chemin dédié, pas sur l’inscription publique' do
    get admin_create_new_user_url

    assert_select 'form[action=?][method=?]', admin_create_new_user_do_path, 'post'
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un agent est créé rattaché à son service et invité (critique)' do
    assert_emails 1 do
      créé = créer(rôle: 'agent', service_ids: [services(:informatique).id])

      assert_not_nil créé
      assert_equal [services(:informatique)], créé.services.to_a
      assert_equal organisations(:mairie_paris), créé.organisation
      assert_redirected_to user_url(créé)
    end
  end

  # exactement ce qui était arrivé à l'ancienne action create_new_user_do.
  test 'tous les champs du formulaire de création sont enregistrés (critique)' do
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

  test 'un utilisateur sans service n’est pas créé (critique)' do
    assert_no_emails do
      assert_no_difference -> { User.count } do
        créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)
      end
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'doit comporter au moins un service'
  end

  # qui n'est PAS `blank?` : la garde doit dépiler le tableau, pas le tester tel quel.
  test 'un utilisateur dont la sélection de services est vidée n’est pas créé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
            service_ids: [''])
    end

    assert_response :unprocessable_content
  end

  test 'un utilisateur rattaché à un service d’une autre organisation n’est pas créé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:service_marseille).id])
    end

    assert_response :unprocessable_content
  end

  test 'un agent rattaché à deux services n’est pas créé (critique)' do
    assert_no_difference -> { User.count } do
      créer(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])
    end

    assert_response :unprocessable_content
    assert_includes response.body, 'un seul service'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un adhérent peut être créé avec plusieurs services' do
    créé = créer(rôle: 'adhérent', address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35,
                 service_ids: [services(:informatique).id, services(:technique).id])

    assert_not_nil créé
    assert_equal 2, créé.services.count
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un manager ne peut pas créer un utilisateur rattaché à un service hors de son périmètre (critique)' do
    hors_périmètre = services(:comptabilite) # aucun manager de Paris n'y est rattaché

    assert_no_difference -> { User.count } do
      créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [hors_périmètre.id])
    end

    assert_response :unprocessable_content
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un manager peut créer un utilisateur rattaché à l’un de ses services' do
    créé = créer(connecté: users(:hidalgo), rôle: 'agent', service_ids: [services(:technique).id])

    assert_not_nil créé
    assert_equal [services(:technique)], créé.services.to_a
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un administrateur crée un utilisateur dans tout service de son organisation et y garde accès (critique)' do
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
  test 'un service hors périmètre soumis avec un service valide est ignoré à la création d’un utilisateur' do
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

  test 'un manager ne crée que des agents, quel que soit le rôle demandé (critique)' do
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
  test 'le mail de réinitialisation de mot de passe part, sans mail log, même pour un compte sans service (critique)' do
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
  test 'une adresse connue reçoit son mail de réinitialisation de mot de passe (critique)' do
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
  test 'une adresse inconnue ne déclenche aucun mail de réinitialisation de mot de passe (critique)' do
    # Doit etre déconnecté
    sign_out @user

    assert_no_emails do
      post user_password_url, params: { user: { email: 'personne@example.test' } }
    end

    assert_redirected_to new_user_session_path
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un utilisateur sans email n’est pas créé' do
    assert_no_difference('User.count') do
      post admin_create_new_user_do_url, params: { user: { nom: 'SANS', prénom: 'Email', email: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_user_url(@user)
    assert_response :success
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le formulaire de modification présélectionne les services actuels (critique)' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:technique).id]

    get edit_user_url(adhérent)

    select_html = response.body[/<select[^>]*id="user_service_ids".*?<\/select>/m].to_s
    sélectionnés = select_html.scan(/<option selected="selected" value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, sélectionnés.sort
  end

  # unique sérialise le tableau en une chaîne que `permit(service_ids: [])` rejette.
  test 'le formulaire de modification ouvert par un manager renvoie un champ caché par service (critique)' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo)

    get edit_user_url(adhérent)

    assert_select 'select#user_service_ids', { count: 0 }, 'un manager ne réaffecte pas les services'
    valeurs = response.body.scan(/name="user\[service_ids\]\[\]"[^>]*value="(\d+)"/).flatten.map(&:to_i)
    assert_equal adhérent.services.ids.sort, valeurs.sort
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le formulaire de modification propose les mots clés déjà utilisés' do
    users(:bond).update!(tag_list: 'secteur-nord')

    get edit_user_url(users(:martin_technique_paris))

    assert_response :success
    assert_includes assigns(:users_tags).map(&:name), 'secteur-nord'
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le formulaire de modification ne propose pas les mots clés d’une autre organisation (critique)' do
    users(:nettoyeur_marseille).update!(tag_list: 'secret-marseille')

    get edit_user_url(users(:martin_technique_paris))

    assert_response :success
    assert_not_includes assigns(:users_tags).map(&:name), 'secret-marseille'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un utilisateur est modifié lorsque les paramètres sont valides' do
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

  test 'un agent qui soumet le rôle administrateur sur sa propre fiche garde son rôle (critique)' do
    bond = users(:bond)
    sign_in bond

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'administrateur' } }

    assert bond.reload.agent?
  end

  test 'un manager qui soumet le rôle manager sur un agent laisse son rôle inchangé (critique)' do
    sign_in users(:hidalgo)
    bond = users(:bond)

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'manager' } }

    assert bond.reload.agent?
  end

  test 'un service d’une autre organisation soumis sur un utilisateur laisse ses services inchangés (critique)' do
    sign_in users(:hidalgo)
    bond = users(:bond)
    services_avant = bond.services.sort_by(&:id)

    patch user_url(bond), params: { user: { nom: bond.nom, service_ids: [services(:service_marseille).id] } }

    assert_not_includes bond.reload.services, services(:service_marseille)
    assert_equal services_avant, bond.services.sort_by(&:id)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un utilisateur dont l’email est vidé n’est pas modifié' do
    patch user_url(@user), params: { user: { email: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @user.reload.email
  end

  # les laisserait invisibles. Seule la modale d'absence reste en turbo-stream.
  test 'un refus de modification réaffiche le formulaire complet en HTML, pas en turbo-stream' do
    patch user_url(@user), params: { user: { email: '' } }, as: :turbo_stream

    assert_response :unprocessable_content
    assert_no_match(/turbo-stream/, response.body)
    assert_select "form##{ActionView::RecordIdentifier.dom_id(@user)}"
    assert_select 'select#user_service_ids[data-controller~=?]', 'slim-select'
  end

  test 'un refus de modification depuis la modale d’absence remplace le formulaire d’absence' do
    patch user_url(@user),
          params: { user: { absences_attributes: { '0' => { du: '2030-08-10', au: '2030-08-01',
                                                            motif: 'formation' } } },
                    from_absence_modal: '1' },
          as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match(/absence_form/, response.body)
  end

  test 'un refus de validation à la modification ne laisse pas les services modifiés en base' do
    agent = users(:bond)
    services_avant = agent.services.ids
    ajout = services(:service_paris).id

    patch user_url(agent), params: {
      user: { nom: agent.nom, service_ids: (services_avant + [ajout]).map(&:to_s) }
    }

    assert_response :unprocessable_content
    assert_equal services_avant, agent.reload.services.ids
  end

  test 'le changement de service d’un agent est enregistré' do
    agent = users(:bond)
    nouveau = services(:service_paris)

    patch user_url(agent), params: { user: { nom: agent.nom, service_ids: ['', nouveau.id.to_s] } }

    assert_equal [nouveau.id], agent.reload.services.ids
  end

  test 'une fiche enregistrée sans toucher aux services les conserve' do
    agent = users(:bond)
    services_avant = agent.services.ids

    patch user_url(agent), params: { user: { nom: agent.nom, service_ids: services_avant.map(&:to_s) } }

    assert_equal services_avant, agent.reload.services.ids
  end

  test 'un manager qui enregistre une fiche ne perd pas les services hors de son périmètre' do
    adhérent = users(:weil)
    adhérent.service_ids = [services(:informatique).id, services(:comptabilite).id]
    sign_in users(:hidalgo) # rattaché à service_paris / informatique / technique

    patch user_url(adhérent), params: { user: { nom: adhérent.nom, service_ids: adhérent.service_ids } }

    assert_equal 2, adhérent.reload.services.count
    assert_includes adhérent.services, services(:comptabilite)
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

  test 'un agent ne peut pas supprimer une absence depuis son propre profil' do
    agent = users(:bond)
    absence = absences(:one)
    sign_in agent

    assert_no_difference('Absence.count') do
      patch user_url(agent),
            params: { user: { absences_attributes: { '0' => { id: absence.id, _destroy: '1' } } } }
    end
  end

  test 'les mots clés d’un utilisateur sont modifiables depuis sa fiche' do
    agent = users(:bond)

    patch user_url(agent), params: { user: { nom: agent.nom, tag_list: ['', 'secteur-nord', 'astreinte'] } }

    assert_equal %w[secteur-nord astreinte], agent.reload.tag_list
  end

  test 'les mots clés sont retirés lorsque leur champ est vidé' do
    agent = users(:bond)
    agent.update!(tag_list: 'secteur-nord')

    patch user_url(agent), params: { user: { nom: agent.nom, tag_list: [''] } }

    assert_empty agent.reload.tag_list
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un administrateur ne peut ni afficher ni modifier un utilisateur d’une autre organisation (critique)' do
    autre_org = users(:agent_marseille)

    get user_url(autre_org)
    assert_redirected_to root_path

    patch user_url(autre_org), params: { user: { nom: 'FORGE' } }
    assert_redirected_to root_path
    assert_not_equal 'FORGE', autre_org.reload.nom
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un utilisateur est désactivé lorsqu’il est supprimé' do
    assert_difference('User.count', -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end

  # Agent calendrier
  test 'le calendrier des agents est affiché avec succès' do
    get agent_calendrier_users_url
    assert_response :success
  end

  test 'le calendrier des agents filtré par une recherche est affiché avec succès' do
    get agent_calendrier_users_url(search: 'algo')
    assert_response :success
  end

  test 'le menu services du calendrier des agents propose toute organisation à un administrateur' do
    get agent_calendrier_users_url

    assert_response :success
    assert_select "select[name='services[]'] option", { text: 'Comptabilité' }
  end

  test 'le filtre services du calendrier des agents est masqué pour un manager mono-service' do
    sign_in users(:manager_marseille)

    get agent_calendrier_users_url

    assert_response :success
    assert_select "select[name='services[]']", false,
                  'le filtre services doit être masqué pour un manager mono-service'
  end

  # ==================== TESTS CRITIQUES ====================
  # Le périmètre de visibilité et le cloisonnement entre communes dérivent du
  # rattachement aux services : un filtre inopérant expose des agents d'un autre
  # service, un filtre non borné ceux d'une autre organisation.
  test 'le calendrier des agents filtré sur un service ne montre que les agents de ce service (critique)' do
    agent_du_service = users(:bond)               # technique
    agent_autre_service = users(:agent_whatsapp)  # service_paris

    get agent_calendrier_users_url, params: { services: [services(:technique).id] }

    assert_response :success
    assert_select 'a[href=?]', user_path(agent_du_service), { minimum: 1 }
    assert_select 'a[href=?]', user_path(agent_autre_service), { count: 0 },
                  'un agent hors du service demandé ne doit pas apparaître dans le calendrier'
  end

  test 'le calendrier des agents dont le filtre est vidé montre tout le périmètre (critique)' do
    hors_services_de_l_administrateur = users(:john_wick) # comptabilité

    get agent_calendrier_users_url, params: { services: [''] }

    assert_response :success
    assert_select 'a[href=?]', user_path(hors_services_de_l_administrateur), { minimum: 1 }
  end

  test 'un manager ne peut pas forger un service hors de son périmètre dans le calendrier des agents (critique)' do
    sign_in users(:hidalgo) # service_paris / informatique / technique
    hors_perimetre = users(:john_wick) # comptabilité

    get agent_calendrier_users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select 'a[href=?]', user_path(hors_perimetre), { count: 0 }
    assert_select "select[name='services[]'] option", { text: 'Comptabilité', count: 0 }
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'l’import d’utilisateurs appelé en GET redirige vers l’accueil sans planter' do
    get import_do_users_url

    assert_redirected_to root_path
  end

  test 'un import d’utilisateurs avec un champ de fichier vide ramène au formulaire' do
    post import_do_users_url(upload: '')

    assert_redirected_to import_users_url
  end

  test 'un import d’utilisateurs sans fichier joint affiche une alerte nommant le fichier manquant' do
    post import_do_users_url

    assert_redirected_to import_users_url
    assert_equal 'Manque le fichier source pour pouvoir lancer l\'importation !', flash[:alert]
  end

  test 'le lien d’accès d’un utilisateur est renvoyé' do
    post inviter_user_url(@user)

    assert_redirected_to user_path(@user)
    assert_match(/renvoyé avec succès/i, flash[:notice].to_s)
  end

  # compte peut changer son mot de passe.
  test 'le formulaire de changement de mot de passe est affiché avec succès' do
    sign_in @user
    get edit_password_user_url(@user)

    assert_response :success
  end

  test 'un nouveau mot de passe est enregistré' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'Nouveau-MotDePasse-42!' } }

    assert_redirected_to user_url(@user)
    assert @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'un nouveau mot de passe dont la confirmation diffère n’est pas enregistré' do
    sign_in @user
    patch update_password_user_url(@user),
          params: { user: { password: 'Nouveau-MotDePasse-42!', password_confirmation: 'autre-chose' } }

    assert_response :unprocessable_content
    assert_not @user.reload.valid_password?('Nouveau-MotDePasse-42!')
  end

  test 'un compte désactivé est réactivé' do
    desactive = users(:agent_whatsapp) # service_paris, donc dans le périmètre de l'administrateur
    desactive.discard

    patch reactivate_user_url(desactive)

    assert_redirected_to users_path
    assert_not desactive.reload.discarded?
  end

  test 'la réactivation d’un compte déjà actif est refusée avec une alerte' do
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
