require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bond)
    sign_in users(:hidalgo)
  end

  # Index
  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get index with export xls" do
    get users_url,  params: {
      format: :xls
    }

    assert_response :success
    assert_equal "application/xls", response.content_type
  end

  test "should get index with param search" do
    get users_url(search: "tonte")
    assert_response :success
  end

  test "should get index with param rôle" do
    get users_url(rôle: "agent")
    assert_response :success
  end

  test "should get index with param absent" do
    get users_url(absent: true)
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: {
        user: {
          nom: "Foo",
          prénom: "Bar",
          email: "email@example.com",
          password: "0DcPIZIq0+f5SvCf",
          rôle: "agent",
          organisation: organisations(:mairie_paris),
          service_ids: [services(:service_paris).id]
        }
      }
    end

    assert_redirected_to user_url(User.last)
  end

  # Show
  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: {
      user: {
        email: @user.email,
        password: "0DcPIZIq0+f5SvCf",
        rôle: @user.rôle,
        organisation: @user.organisation
      }
    }
    assert_redirected_to user_url(@user)
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete user_url(@user)
    end

    assert_redirected_to users_url
  end

  # Agent calendrier
  test "should get agent_calendrier" do
    get agent_calendrier_users_url
    assert_response :success
  end

  test "should get agent_calendrier with param search" do
    get agent_calendrier_users_url(search: "algo")
    assert_response :success
  end

  test "should get import" do
    get import_users_url
    assert_response :success
  end

  # Import_do
  test "should no import without param upload" do
    get import_do_users_url
    assert_redirected_to root_path
  end

  test "should no import with param upload empty" do
    post import_do_users_url(upload: "")
    assert_redirected_to import_users_url
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
