require "test_helper"

class CommandesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @commande = commandes(:commande_paris)
    sign_in users(:hidalgo)
  end

  test "should get index" do
    get commandes_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_commande_url
  #   assert_response :success
  # end

  # test "should create commande" do
  #   assert_difference("Commande.count") do
  #     post commandes_url, params: { commande: {} }
  #   end
  #
  #   assert_redirected_to commande_url(Commande.last)
  # end

  test "should show commande" do
    get commande_url(@commande)
    assert_response :success
  end

  # test "should get edit" do
  #   get edit_commande_url(@commande)
  #   assert_response :success
  # end
  #
  # test "should update commande" do
  #   patch commande_url(@commande), params: { commande: {} }
  #   assert_redirected_to commande_url(@commande)
  # end

  test "should destroy commande" do
    assert_difference("Commande.count", -1) do
      delete commande_url(@commande)
    end

    assert_redirected_to commandes_url
  end
end
