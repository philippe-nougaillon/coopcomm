# require "test_helper"

# class MouvementsControllerTest < ActionDispatch::IntegrationTest
#   setup do
#     @mouvement = mouvements(:one)
#   end

#   test "should get index" do
#     get mouvements_url
#     assert_response :success
#   end

#   test "should get new" do
#     get new_mouvement_url
#     assert_response :success
#   end

#   test "should create mouvement" do
#     assert_difference("Mouvement.count") do
#       post mouvements_url, params: { mouvement: { slug: @mouvement.slug, tool_id: @mouvement.tool_id, état: @mouvement.état } }
#     end

#     assert_redirected_to mouvement_url(Mouvement.last)
#   end

#   test "should show mouvement" do
#     get mouvement_url(@mouvement)
#     assert_response :success
#   end

#   test "should get edit" do
#     get edit_mouvement_url(@mouvement)
#     assert_response :success
#   end

#   test "should update mouvement" do
#     patch mouvement_url(@mouvement), params: { mouvement: { slug: @mouvement.slug, tool_id: @mouvement.tool_id, état: @mouvement.état } }
#     assert_redirected_to mouvement_url(@mouvement)
#   end

#   test "should destroy mouvement" do
#     assert_difference("Mouvement.count", -1) do
#       delete mouvement_url(@mouvement)
#     end

#     assert_redirected_to mouvements_url
#   end
# end
