# frozen_string_literal: true

require 'test_helper'

class DashboardAdherentTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:weil)
  end

  test 'le tableau de bord est accessible depuis le menu' do
    get home_path

    assert_response :success
    assert_dom "a[href=?]", dashboard_path

    get dashboard_path

    assert_response :success
    assert_dom 'h1', text: 'Tableau de bord - Adhérent'
  end

  test 'le tableau de bord est accessible depuis les accès rapides' do
    get home_path

    assert_response :success
    assert_dom "a[href=?]", dashboard_path, text: /Voir le tableau de bord/

    get dashboard_path

    assert_response :success
    assert_dom 'h1', text: 'Tableau de bord - Adhérent'
  end
end
