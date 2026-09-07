# frozen_string_literal: true

require 'test_helper'

class DashboardExportXlsTest < ActionDispatch::IntegrationTest
  test 'un manager qui demande le tableau de bord au format xls reçoit un fichier xls' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.media_type
    assert_match(/filename="#{ERB::Util.url_encode("Dashboard_#{I18n.l Date.today}.xls")}"/,
                 response.headers['Content-Disposition'])
  end

  test 'un adhérent qui demande le tableau de bord au format xls reçoit un fichier xls' do
    sign_in users(:weil)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.media_type
    assert_match(/filename="#{ERB::Util.url_encode("Dashboard_#{I18n.l Date.today}.xls")}"/,
                 response.headers['Content-Disposition'])
  end

  test "l'export du tableau de bord d'un manager est journalisé sous le type dashboard_manager" do
    sign_in users(:hidalgo)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    assert_equal 'dashboard_manager', ExportLog.last.export_type
  end

  test "l'export du tableau de bord d'un adhérent est journalisé sous le type dashboard_adherent" do
    sign_in users(:weil)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    assert_equal 'dashboard_adherent', ExportLog.last.export_type
  end

  test "l'export est journalisé au nom de l'utilisateur et de son organisation" do
    sign_in users(:hidalgo)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    log = ExportLog.last
    assert_equal users(:hidalgo), log.user
    assert_equal organisations(:mairie_paris), log.organisation
  end
end
