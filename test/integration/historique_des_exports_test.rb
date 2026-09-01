# frozen_string_literal: true

require 'test_helper'

class HistoriqueDesExportsTest < ActionDispatch::IntegrationTest
  test "l'export du tableau de bord au format xls figure aussitôt dans l'historique des exports" do
    sign_in users(:administrateur_paris)

    get dashboard_url(format: :xls)

    assert_response :success

    get dashboard_url

    assert_response :success
    assert_dom 'tbody tr', text: /Administrateur Paris/ do
      assert_dom 'td', text: /Dashboard \(Manager\)/
    end
  end
end
