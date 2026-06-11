# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'doit afficher la page welcome' do
    get welcome_url
    assert_response :success
  end

  test 'doit afficher la page welcome en étant connecté' do
    sign_in users(:hidalgo)

    get welcome_url
    assert_response :success
  end

  test "doit afficher le dashboard en tant qu'administrateur" do
    sign_in users(:hidalgo)

    get dashboard_url
    assert_response :success
  end

  test "doit afficher le dashboard en tant qu'adhérent" do
    sign_in users(:weil)

    get dashboard_url
    assert_response :success
  end

  test "ne doit pas accéder au dashboard en tant qu'agent" do
    sign_in users(:martin_technique_paris)

    get dashboard_url
    assert_redirected_to root_url
  end

  test 'doit afficher le dashboard sans intervention avec un manager' do
    sign_in users(:michael_jackson)

    get dashboard_url
    assert_response :success
  end

  test 'doit afficher le dashboard sans intervention avec un adhérent' do
    sign_in users(:emmanuel_valls)

    get dashboard_url
    assert_response :success
  end
end
