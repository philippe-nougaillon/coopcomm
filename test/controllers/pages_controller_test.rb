require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get dashboard with manager" do
    sign_in users(:hidalgo)
    get dashboard_url
    assert_response :success
  end

  test "should get dashboard with adherent" do
    sign_in users(:weil)
    get dashboard_url
    assert_response :success
  end

  test "should get dashboard redirected to root with agent" do
    sign_in users(:martin)
    get dashboard_url
    assert_redirected_to root_path
  end
end
