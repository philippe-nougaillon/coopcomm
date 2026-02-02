require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bond)
    sign_in users(:hidalgo)
  end

  test "should get audits" do
    get admin_audits_url
    assert_response :success
  end

  test "should get create new user" do
    get admin_create_new_user_url
    assert_response :success
  end

  test "should create new user do" do
    assert_difference("User.count") do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: "Foo",
          prénom: "Bar",
          email: "email@example.com",
          password: "password",
          rôle: "adhérent",
          téléphone: "0123456789",
          localisation: "123.123,432.120398",
        }
      }
    end

    assert_redirected_to users_url
  end

  test "should show messagerie" do
    get admin_messagerie_url
    assert_response :success
  end

  test "should no send notification without submit message" do
    assert_no_difference("Notification.count") do
      post admin_send_notification_url, params: {
        message: "Bonjour",
        from_id: users.first.id,
        to_id: users.second.id,
      }
    end

    assert_response :success
  end

  test "should send notification with submit message" do
    assert_difference("Notification.count") do
      post admin_send_notification_url, params: {
        message: "Bonjour",
        from_id: users.first.id,
        to_id: users.second.id,
        submit_message: true
      }
    end

    assert_redirected_to admin_messagerie_path(to_id: users.second.id)
  end

  # test "should get stats" do
  #   sign_in users(:philippe_super_admin)

  #   get admin_stats_url
  #   assert_response :success
  # end
end
