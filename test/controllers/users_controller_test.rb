# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bond)
    sign_in users(:administrateur_paris)
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
    get new_user_url
    assert_response :success
  end

  test 'should create user' do
    assert_difference('User.count') do
      post users_url, params: {
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
      post users_url, params: {
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
      post users_url, params: {
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
      post users_url, params: {
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
