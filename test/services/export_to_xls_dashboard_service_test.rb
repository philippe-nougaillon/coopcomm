# frozen_string_literal: true

require 'test_helper'

# Les deux services produisent un binaire XLS : on relit le classeur avec
# Spreadsheet plutôt que d'asserter qu'un binaire non vide est sorti, sinon une
# transposition décalée dans l'onglet « États par mois » passerait inaperçue.
class ExportToXlsDashboardServiceTest < ActiveSupport::TestCase
  setup do
    @workflow_chart = {
      labels: %w[2026-01 2026-02],
      datasets: [
        { label: 'Nouveau', data: [3, 5], backgroundColor: 'rgba(0,0,0,1)' },
        { label: 'Terminé', data: [1, 0], backgroundColor: 'rgba(1,1,1,1)' }
      ]
    }
  end

  # ==========================================================================
  # A. ExportToXls::DashboardManager
  # ==========================================================================

  test 'le classeur manager contient les six onglets attendus dans l’ordre' do
    book = lire(export_manager)

    assert_equal ['Temps par adhérent', 'Temps par agent', 'États par mois',
                  'Qté par service', 'Temps par service', 'CO2 par mois'],
                 book.worksheets.map(&:name)
  end

  test 'l’onglet des temps par adhérent porte ses en-têtes et ses données' do
    feuille = lire(export_manager).worksheet('Temps par adhérent')

    assert_equal ['Adhérent', 'Temps total'], feuille.row(0).to_a
    assert_equal ['Weil Ariel', 12.5], feuille.row(1).to_a
  end

  test 'l’onglet des temps par agent porte ses en-têtes et ses données' do
    feuille = lire(export_manager).worksheet('Temps par agent')

    assert_equal ['Agent', 'Temps total'], feuille.row(0).to_a
    assert_equal ['Bond James', 8.0], feuille.row(1).to_a
  end

  test 'l’onglet des quantités par service porte ses en-têtes et ses données' do
    feuille = lire(export_manager).worksheet('Qté par service')

    assert_equal %w[Service Quantité], feuille.row(0).to_a
    assert_equal ['Informatique', 4], feuille.row(1).to_a
  end

  test 'l’onglet du CO2 par mois porte ses en-têtes et ses données' do
    feuille = lire(export_manager).worksheet('CO2 par mois')

    assert_equal ['Mois', 'CO2 total'], feuille.row(0).to_a
    assert_equal ['2026-01', 1.5], feuille.row(1).to_a
  end

  # ==========================================================================
  # B. ExportToXls::DashboardAdherent
  # ==========================================================================

  test 'le classeur adhérent contient les six onglets attendus dans l’ordre' do
    book = lire(export_adherent)

    assert_equal ['Temps consommé', 'Temps par mois', 'États par mois',
                  'Qté par service', 'Temps par service', 'CO2 par mois'],
                 book.worksheets.map(&:name)
  end

  test 'l’onglet du temps consommé porte ses en-têtes et ses données' do
    feuille = lire(export_adherent).worksheet('Temps consommé')

    assert_equal %w[Indicateur Temps], feuille.row(0).to_a
    assert_equal ['temps_consomme', 30.0], feuille.row(1).to_a
    assert_equal ['temps_restant', 70.0], feuille.row(2).to_a
  end

  test 'l’onglet des temps par mois porte ses en-têtes et ses données' do
    feuille = lire(export_adherent).worksheet('Temps par mois')

    assert_equal ['Mois', 'Temps total'], feuille.row(0).to_a
    assert_equal ['2026-01', 30.0], feuille.row(1).to_a
  end

  # ==========================================================================
  # C. Transposition de l'onglet « États par mois » (le seul vrai calcul)
  # ==========================================================================

  test 'les en-têtes des états par mois reprennent le libellé de chaque série' do
    feuille = lire(export_manager).worksheet('États par mois')

    assert_equal %w[Mois Nouveau Terminé], feuille.row(0).to_a
  end

  test 'chaque ligne des états par mois croise un mois et la valeur de chaque série' do
    feuille = lire(export_manager).worksheet('États par mois')

    assert_equal ['2026-01', 3, 1], feuille.row(1).to_a
    assert_equal ['2026-02', 5, 0], feuille.row(2).to_a
  end

  test 'la transposition des états par mois est identique côté adhérent' do
    feuille = lire(export_adherent).worksheet('États par mois')

    assert_equal %w[Mois Nouveau Terminé], feuille.row(0).to_a
    assert_equal ['2026-01', 3, 1], feuille.row(1).to_a
  end

  test 'un graphe sans aucun mois ne produit que la ligne d’en-têtes' do
    @workflow_chart = { labels: [], datasets: [{ label: 'Nouveau', data: [] }] }

    feuille = lire(export_manager).worksheet('États par mois')

    assert_equal %w[Mois Nouveau], feuille.row(0).to_a
    assert_equal 1, feuille.rows.count
  end

  test 'une série plus courte que la liste des mois laisse la cellule vide' do
    @workflow_chart = {
      labels: %w[2026-01 2026-02],
      datasets: [{ label: 'Nouveau', data: [3] }]
    }

    feuille = lire(export_manager).worksheet('États par mois')

    assert_equal ['2026-01', 3], feuille.row(1).to_a
    assert_equal ['2026-02', nil], feuille.row(2).to_a
  end

  # ==========================================================================
  # D. Agrégats vides
  # ==========================================================================

  test 'un tableau de bord manager sans donnée produit un classeur lisible' do
    xls = ExportToXls::DashboardManager.new({}, {}, @workflow_chart, {}, {}, {}).call

    assert_equal 6, lire(xls).worksheets.count
  end

  test 'un tableau de bord adhérent sans donnée produit un classeur lisible' do
    xls = ExportToXls::DashboardAdherent.new({}, {}, @workflow_chart, {}, {}, {}).call

    assert_equal 6, lire(xls).worksheets.count
  end

  test 'un onglet sans donnée ne contient que sa ligne d’en-têtes' do
    xls = ExportToXls::DashboardManager.new({}, {}, @workflow_chart, {}, {}, {}).call

    assert_equal 1, lire(xls).worksheet('Temps par adhérent').rows.count
  end

  private

  def export_manager
    ExportToXls::DashboardManager.new(
      { 'Weil Ariel' => 12.5 },
      { 'Bond James' => 8.0 },
      @workflow_chart,
      { 'Informatique' => 4 },
      { 'Informatique' => 20.0 },
      { '2026-01' => 1.5 }
    ).call
  end

  def export_adherent
    ExportToXls::DashboardAdherent.new(
      { 'temps_consomme' => 30.0, 'temps_restant' => 70.0 },
      { '2026-01' => 30.0 },
      @workflow_chart,
      { 'Informatique' => 4 },
      { 'Informatique' => 20.0 },
      { '2026-01' => 1.5 }
    ).call
  end

  def lire(binaire)
    Spreadsheet.open(StringIO.new(binaire))
  end
end
