require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "le serveur se lance correctement" do
    get rails_health_check_url
    assert_response :success
  end
end
