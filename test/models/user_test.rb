require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "the truth" do
    assert true
  end

  test "test basique" do
    user = users(:hidalgo)
    assert_equal user.nom, "Hidalgo"
  end
end
