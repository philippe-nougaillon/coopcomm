# frozen_string_literal: true

require 'test_helper'

class ExportToXlsDashboardManagerTest < ActiveSupport::TestCase
  ONGLETS = ['Temps par adhérent', 'Temps par agent', 'États par mois',
             'Qté par service', 'Temps par service', 'CO2 par mois'].freeze

  setup do
    @workflow_chart = {
      labels: %w[2026-01 2026-02],
      datasets: [
        { label: 'Nouveau', data: [3, 5], backgroundColor: 'rgba(0,0,0,1)' },
        { label: 'Terminé', data: [1, 0], backgroundColor: 'rgba(1,1,1,1)' }
      ]
    }
  end

  test 'le classeur porte les six onglets attendus' do
    assert_equal ONGLETS, lire_fichier_xls(dashboard_manager_xls).worksheets.map(&:name)
  end

  test 'chaque onglet porte une ligne par donnée, sous l’en-tête' do
    book = lire_fichier_xls(dashboard_manager_xls)

    assert_equal [2, 2, 3, 2, 2, 2], ONGLETS.map { |onglet| book.worksheet(onglet).rows.count }
  end

  test 'chaque onglet porte le nombre de colonnes attendu' do
    book = lire_fichier_xls(dashboard_manager_xls)

    assert_equal [2, 2, 3, 2, 2, 2], ONGLETS.map { |onglet| book.worksheet(onglet).row(0).size }
  end

  test 'sans aucun agrégat, chaque onglet est réduit à sa ligne d’en-tête' do
    book = lire_fichier_xls(dashboard_manager_xls_vide)

    assert_equal ONGLETS, book.worksheets.map(&:name)
    assert_equal [1] * 6, ONGLETS.map { |onglet| book.worksheet(onglet).rows.count }
  end

  test 'le temps total d’un adhérent est écrit en regard de son nom' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('Temps par adhérent')

    assert_equal ['Weil Ariel', 12.5], feuille.row(1).to_a
  end

  test 'chaque ligne des états par mois croise un mois et la valeur de chaque série' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('États par mois')

    assert_equal %w[Mois Nouveau Terminé], feuille.row(0).to_a
    assert_equal ['2026-01', 3, 1], feuille.row(1).to_a
    assert_equal ['2026-02', 5, 0], feuille.row(2).to_a
  end

  test 'une série plus courte que la liste des mois laisse la cellule vide' do
    @workflow_chart = { labels: %w[2026-01 2026-02], datasets: [{ label: 'Nouveau', data: [3] }] }

    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('États par mois')

    assert_equal ['2026-01', 3], feuille.row(1).to_a
    assert_equal ['2026-02', nil], feuille.row(2).to_a
  end

  private

  def dashboard_manager_xls
    ExportToXls::DashboardManager.new(
      { 'Weil Ariel' => 12.5 },
      { 'Bond James' => 8.0 },
      @workflow_chart,
      { 'Informatique' => 4 },
      { 'Informatique' => 20.0 },
      { '2026-01' => 1.5 }
    ).call
  end

  def dashboard_manager_xls_vide
    ExportToXls::DashboardManager.new({}, {}, { labels: [], datasets: [] }, {}, {}, {}).call
  end

  def lire_fichier_xls(binaire)
    Spreadsheet.open(StringIO.new(binaire))
  end
end
