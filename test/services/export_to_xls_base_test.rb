# frozen_string_literal: true

require 'test_helper'

# Classe mère des cinq exports XLS. Elle n'a pas de `call` : ses méthodes se
# testent directement, aucun export ne pouvant les atteindre autrement.
class ExportToXlsBaseTest < ActiveSupport::TestCase
  setup do
    @base = ExportToXls::Base.new
  end

  test 'ajouter une feuille la crée sous son nom et rend l’export pour le chaînage' do
    retour = @base.add_worksheet('Liste des agents')

    assert_same @base, retour
    assert_equal ['Liste des agents'], lire_fichier_xls(@base.build_file).worksheets.map(&:name)
  end

  test 'deux feuilles ajoutées sont créées dans l’ordre' do
    @base.add_worksheet('Première').add_worksheet('Seconde')

    assert_equal %w[Première Seconde], lire_fichier_xls(@base.build_file).worksheets.map(&:name)
  end

  test 'les en-têtes sont écrits sur la première ligne' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom Email])

    assert_equal %w[Nom Prénom Email], premiere_feuille(@base).row(0).to_a
  end

  test 'chaque donnée occupe une ligne, sous l’en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([%w[Weil Ariel], %w[Bond James], %w[Martin Michel]])

    assert_equal 4, premiere_feuille(@base).rows.count
    assert_equal %w[Weil Ariel], premiere_feuille(@base).row(1).to_a
    assert_equal %w[Martin Michel], premiere_feuille(@base).row(3).to_a
  end

  test 'sans donnée, le classeur est réduit à sa ligne d’en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([])

    assert_equal 1, premiere_feuille(@base).rows.count
  end

  test 'une donnée nulle est écrite sans lever' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Téléphone])
    @base.setup_data([['Weil', nil]])

    assert_equal ['Weil', nil], premiere_feuille(@base).row(1).to_a
  end

  test 'seules les valeurs numériques sont centrées' do
    @base.add_worksheet('Feuille').add_headers(['Nom', 'Service', 'Interventions'])
    @base.setup_data([['Weil', 'Informatique', 4]])

    ligne = premiere_feuille(@base).row(1)

    assert_equal :center, ligne.format(2).horizontal_align
    assert_not_equal :center, ligne.format(1).horizontal_align
  end

  test 'le classeur construit est un binaire relu comme un fichier XLS' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])

    binaire = @base.build_file

    assert_equal Encoding::BINARY, binaire.encoding
    assert_equal ['Weil'], lire_fichier_xls(binaire).worksheet(0).row(1).to_a
  end

  test 'construire le classeur deux fois rend le même binaire' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])

    assert_equal @base.build_file, @base.build_file
  end

  test 'la largeur d’une colonne est la longueur de sa plus longue cellule plus quatre' do
    description = 'Tonte des espaces verts du centre-bourg'
    @base.add_worksheet('Feuille').add_headers(['Description'])
    @base.setup_data([[description]])
    @base.build_file

    assert_equal description.length + 4, premiere_feuille(@base).column(0).width
  end

  test 'la largeur d’une colonne suit son en-tête quand il est plus long que les données' do
    @base.add_worksheet('Feuille').add_headers(["Nombre d'interventions"])
    @base.setup_data([[4]])
    @base.build_file

    assert_equal "Nombre d'interventions".length + 4, premiere_feuille(@base).column(0).width
  end

  test 'une colonne courte garde la largeur minimale de dix' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])
    @base.build_file

    assert_equal 10, premiere_feuille(@base).column(0).width
  end

  private

  def premiere_feuille(service)
    lire_fichier_xls(service.build_file).worksheet(0)
  end

  def lire_fichier_xls(binaire)
    Spreadsheet.open(StringIO.new(binaire))
  end
end
