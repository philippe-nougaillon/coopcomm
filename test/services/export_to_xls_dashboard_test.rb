# frozen_string_literal: true

require 'test_helper'

class ExportToXlsDashboardTest < ActiveSupport::TestCase
  ONGLETS_MANAGER = ['Agents', 'Interventions', 'Outils 2026', 'CRM'].freeze

  test 'le classeur d’un manager porte une feuille par tuile de l’accueil, le calendrier des outils compris' do
    assert_equal ONGLETS_MANAGER, lire_fichier_xls(dashboard_manager_xls).worksheets.map(&:name)
  end

  test 'le classeur d’un adhérent porte ses conventions à la place du calendrier des outils' do
    assert_equal %w[Agents Interventions Conventions CRM], lire_fichier_xls(dashboard_adherent_xls).worksheets.map(&:name)
  end

  test 'chaque feuille porte une ligne par donnée, sous l’en-tête' do
    book = lire_fichier_xls(dashboard_manager_xls)

    assert_equal [3, 5, 3, 5], ONGLETS_MANAGER.map { |onglet| book.worksheet(onglet).rows.count }
  end

  test 'chaque feuille porte le nombre de colonnes attendu' do
    book = lire_fichier_xls(dashboard_manager_xls)

    assert_equal [6, 7, 2, 5], ONGLETS_MANAGER.map { |onglet| book.worksheet(onglet).row(0).size }
  end

  test 'la feuille des conventions porte une ligne par convention, sous l’en-tête de sept colonnes' do
    feuille = lire_fichier_xls(dashboard_adherent_xls).worksheet('Conventions')

    assert_equal 2, feuille.rows.count
    assert_equal 7, feuille.row(0).size
  end

  test 'sans aucune donnée, chaque feuille est réduite à sa ligne d’en-tête' do
    book = lire_fichier_xls(dashboard_manager_xls_vide)

    assert_equal ONGLETS_MANAGER, book.worksheets.map(&:name)
    assert_equal [1] * 4, ONGLETS_MANAGER.map { |onglet| book.worksheet(onglet).rows.count }
  end

  test 'l’activité d’un agent est écrite avec son taux de validation arrondi et sa note, vides sans intervention' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('Agents')

    assert_equal ['Martin Michel', 6.5, 3, 67, 4.2, 2], feuille.row(1).to_a
    assert_equal ['Bond James', 0.0, 0, nil, nil, 0], feuille.row(2).to_a
  end

  test 'une ligne des interventions croise un service et un mois : ses quatre états, puis le temps réel plus le temps prévu' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('Interventions')

    assert_equal ['Technique', '2026-01', 3, 1, 0, 0, 6.5], feuille.row(3).to_a
  end

  test 'les réservations de matériel sont écrites jour par jour, dans l’ordre des jours' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('Outils 2026')

    assert_equal ['2026-02-10', 2], feuille.row(1).to_a
    assert_equal ['2026-02-14', 1], feuille.row(2).to_a
  end

  test 'une convention est écrite avec ses heures conventionnées, consommées et prévues' do
    feuille = lire_fichier_xls(dashboard_adherent_xls).worksheet('Conventions')

    assert_equal ['Weil Ariel', 'Informatique', '2026-01-01', '2026-12-31', 100.0, 30.0, 4.0], feuille.row(1).to_a
  end

  # ==================== TESTS CRITIQUES ====================
  # Les montants du CRM sont de l'argent : chaque ligne doit croiser le bon service et le bon mois.
  test 'une ligne du CRM croise un service et un mois avec ses montants de devis, de commandes et de factures (critique)' do
    feuille = lire_fichier_xls(dashboard_manager_xls).worksheet('CRM')

    assert_equal ['Technique', '2026-01', 500.0, 0, 0], feuille.row(3).to_a
    assert_equal ['Technique', '2026-02', 0, 400.0, 200.0], feuille.row(4).to_a
  end

  # ==================== /TESTS CRITIQUES ====================

  private

  def dashboard_manager_xls
    ExportToXls::Dashboard.new(agents, donnees_graphes.merge(reservations: { '2026-02-14' => [1], '2026-02-10' => [2] }), nil).call
  end

  def dashboard_adherent_xls
    ExportToXls::Dashboard.new(agents, donnees_graphes.merge(reservations: nil),
                               [{ adherent: 'Weil Ariel', service: 'Informatique', du: '2026-01-01', au: '2026-12-31',
                                  conventionnees: 100.0, consommees: 30.0, prevues: 4.0 }]).call
  end

  def dashboard_manager_xls_vide
    ExportToXls::Dashboard.new([], { services: [], mois: [], annee: 2026, etats: {}, temps: {}, prevus: {}, crm: {}, reservations: {} },
                               nil).call
  end

  def agents
    [{ libellé: 'Martin Michel', temps: 6.5, nb: 3, validees: 2, note: 4.2, avis: 2 },
     { libellé: 'Bond James', temps: 0.0, nb: 0, validees: 0, note: nil, avis: 0 }]
  end

  # Deux services sur deux mois ; Technique en janvier : trois « nouveau », un « terminé », 4 h réelles et 2,5 h prévues.
  def donnees_graphes
    { services: %w[Informatique Technique], mois: %w[2026-01 2026-02], annee: 2026,
      etats: { 'Informatique' => { '2026-01' => etats(0, 0, 0, 0), '2026-02' => etats(1, 0, 0, 0) },
               'Technique' => { '2026-01' => etats(3, 1, 0, 0), '2026-02' => etats(0, 0, 2, 1) } },
      temps: { 'Informatique' => { '2026-01' => 0, '2026-02' => 0 }, 'Technique' => { '2026-01' => 4.0, '2026-02' => 8.0 } },
      prevus: { 'Informatique' => { '2026-01' => 0, '2026-02' => 2.0 }, 'Technique' => { '2026-01' => 2.5, '2026-02' => 0 } },
      crm: { 'Informatique' => { '2026-01' => montants(0, 0, 0), '2026-02' => montants(0, 0, 50.0) },
             'Technique' => { '2026-01' => montants(500.0, 0, 0), '2026-02' => montants(0, 400.0, 200.0) } } }
  end

  def etats(nouveau, termine, valide, refuse)
    { Intervention::NOUVEAU => nouveau, Intervention::TERMINE => termine, Intervention::VALIDE => valide, Intervention::REFUSE => refuse }
  end

  def montants(devis, commandes, factures)
    { devis: devis, commandes: commandes, factures: factures }
  end

  def lire_fichier_xls(binaire)
    Spreadsheet.open(StringIO.new(binaire))
  end
end
