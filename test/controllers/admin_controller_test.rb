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
          password: "0DcPIZIq0+f5SvCf",
          rôle: "adhérent",
          téléphone: "0123456789",
          address: "Mairie de Paris",
          latitude: 123.123,
          longitude: 432.120398,
        }
      }
    end

    assert_redirected_to users_url
  end
end
