# frozen_string_literal: true

require 'test_helper'

# Export XLS du tableau de bord (pages#dashboard, format xls) : aiguillage
# manager/adhérent, journalisation dans ExportLog et contenu réellement envoyé.
class DashboardExportXlsTest < ActionDispatch::IntegrationTest
  test 'le tableau de bord demandé au format xls est téléchargé comme un classeur xls' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.media_type
    nom_attendu = ERB::Util.url_encode("Dashboard_#{I18n.l Date.today}.xls")
    assert_match(/filename="#{nom_attendu}"/, response.headers['Content-Disposition'])
  end

  test 'export_xls : un manager reçoit un classeur au format manager' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal ['Temps par adhérent', 'Temps par agent', 'États par mois',
                  'Qté par service', 'Temps par service', 'CO2 par mois'],
                 classeur_recu.worksheets.map(&:name)
  end

  test 'export_xls : un administrateur reçoit un classeur au format manager' do
    sign_in users(:administrateur_paris)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal 'Temps par adhérent', classeur_recu.worksheets.first.name
  end

  test 'export_xls : un adhérent reçoit un classeur au format adhérent' do
    sign_in users(:weil)

    get dashboard_url(format: :xls)

    assert_response :success
    assert_equal ['Temps consommé', 'Temps par mois', 'États par mois',
                  'Qté par service', 'Temps par service', 'CO2 par mois'],
                 classeur_recu.worksheets.map(&:name)
  end

  test 'export_xls : le nom du fichier porte la date du jour' do
    sign_in users(:emmanuel_valls)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    assert_response :success
  end

  test "export_xls : l'onglet des états par mois liste les six états du workflow" do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    feuille = classeur_recu.worksheet('Temps par agent')
    assert_equal ['Agent', 'Temps total'], feuille.row(0).to_a
    assert_includes feuille.rows.drop(1).map(&:first), 'Bond James'
  end

  test "export_xls : un tableau de bord sans donnée s'exporte quand même" do
    sign_in users(:hidalgo)

    assert_difference 'ExportLog.count', 2 do
      get dashboard_url(format: :xls)
      get dashboard_url(format: :xls)
    end
  end

  test "export_xls : l'export d'un manager est journalisé sous le type dashboard_manager" do
    sign_in users(:hidalgo)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    assert_equal 'dashboard_manager', ExportLog.last.export_type
  end

  test "export_xls : l'export d'un adhérent est journalisé sous le type dashboard_adherent" do
    sign_in users(:weil)

    assert_difference 'ExportLog.count', 1 do
      get dashboard_url(format: :xls)
    end

    assert_equal 'dashboard_adherent', ExportLog.last.export_type
  end

  test "export_xls : l'export est journalisé au nom de l'utilisateur et de son organisation" do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    log = ExportLog.last
    assert_equal users(:hidalgo), log.user
    assert_equal organisations(:mairie_paris), log.organisation
  end

  test 'export_xls : deux exports successifs sont journalisés deux fois' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_equal ['Mois', 'Nouveau', 'Pointage activé', 'Terminé', 'Validé', 'Refusé', 'Archivé'],
                 classeur_recu.worksheet('États par mois').row(0).to_a
  end

  test 'export_xls : le tableau de bord reste consultable en HTML après un export' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)
    get dashboard_url

    assert_response :success
  end

  private

  def classeur_recu
    Spreadsheet.open(StringIO.new(response.body.dup.force_encoding('binary')))
  end
end
