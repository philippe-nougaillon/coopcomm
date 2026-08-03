# frozen_string_literal: true

require 'test_helper'

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:philippe_super_admin)

    # Permet à l'utilisateur philippe_super_admin d'être considéré comme un super admin automatiquement
    ENV['SUPER_ADMIN'] = @super_admin.email

    @newsletter = newsletters(:bond)
  end

  test 'should get index' do
    sign_in @super_admin
    get newsletters_url
    assert_response :success
  end

  test 'should get index with export xls' do
    sign_in @super_admin
    get users_url, params: {
      format: :xls
    }

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

  # test "should get new" do
  #   get new_newsletter_url
  #   assert_response :success
  # end

  test 'should create newsletter' do
    assert_difference('Newsletter.count') do
      get new_newsletter_url, params: { email: "#{@newsletter.email}m" }
    end

    assert_response :success
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

  test 'should destroy newsletter as super_admin' do
    sign_in @super_admin
    assert_difference('Newsletter.count', -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to newsletters_url
  end

  test 'should destroy newsletter from unsubscribe link' do
    assert_difference('Newsletter.count', -1) do
      delete newsletter_url(@newsletter)
    end

    assert_redirected_to root_url
  end

  test 'index exporte les inscrits au format XLS' do
    sign_in @super_admin

    get newsletters_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

  test 'une inscription avec une adresse déjà connue est signalée sans doublon' do
    assert_no_difference('Newsletter.count') do
      get new_newsletter_url(email: @newsletter.email)
    end

    assert_response :success
    assert_match(/existe déjà une inscription/i, response.body)
  end
end
