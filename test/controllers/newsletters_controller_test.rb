require "test_helper"

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @newsletter = newsletters(:bond)
  end

  test "should get index" do
    sign_in users(:philippe_super_admin)
    get newsletters_url
    assert_response :success
  end

  # test "should get new" do
  #   get new_newsletter_url
  #   assert_response :success
  # end

  test "should create newsletter" do
    assert_difference("Newsletter.count") do
      post newsletters_url, params: { newsletter: { email: @newsletter.email + "m" } }
    end

    assert_redirected_to root_path
  end

  # test "should show newsletter" do
  #   get newsletter_url(@newsletter)
  #   assert_response :success
  # end

  # test "should get edit" do
  #   get edit_newsletter_url(@newsletter)
  #   assert_response :success
  # end

  # test "should update newsletter" do
  #   patch newsletter_url(@newsletter), params: { newsletter: { email: @newsletter.email } }
  #   assert_redirected_to newsletter_url(@newsletter)
  # end

  test "should destroy newsletter as super_admin" do
    sign_in users(:philippe_super_admin)
    assert_difference("Newsletter.count", -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to newsletters_url
  end

  test "should destroy newsletter from unsubscribe link" do
    assert_difference("Newsletter.count", -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to root_url
  end
end
