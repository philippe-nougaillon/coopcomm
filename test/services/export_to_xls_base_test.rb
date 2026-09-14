# frozen_string_literal: true

require 'test_helper'

# Classe mère des cinq exports XLS. Elle n'a pas de `call` : ses méthodes se
# testent directement, aucun export ne pouvant les atteindre autrement.
class ExportToXlsBaseTest < ActiveSupport::TestCase
  setup do
    @base = ExportToXls::Base.new
  end

  test 'add_worksheet crée la feuille et renvoie le service pour le chaînage' do
    retour = @base.add_worksheet('Liste des agents')

    assert_same @base, retour
    assert_equal ['Liste des agents'], lire_fichier_xls(@base.build_file).worksheets.map(&:name)
  end

  test 'deux appels à add_worksheet créent deux feuilles dans l’ordre' do
    @base.add_worksheet('Première').add_worksheet('Seconde')

    assert_equal %w[Première Seconde], lire_fichier_xls(@base.build_file).worksheets.map(&:name)
  end

  test 'add_headers écrit les en-têtes sur la première ligne' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom Email])

    assert_equal %w[Nom Prénom Email], premiere_feuille(@base).row(0).to_a
  end

  test 'setup_data écrit une ligne par donnée, sous l’en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([%w[Weil Ariel], %w[Bond James], %w[Martin Michel]])

    assert_equal 4, premiere_feuille(@base).rows.count
    assert_equal %w[Weil Ariel], premiere_feuille(@base).row(1).to_a
    assert_equal %w[Martin Michel], premiere_feuille(@base).row(3).to_a
  end

  test 'setup_data sans donnée laisse le classeur à sa seule ligne d’en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([])

    assert_equal 1, premiere_feuille(@base).rows.count
  end

  test 'setup_data écrit une cellule nulle sans lever' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Téléphone])
    @base.setup_data([['Weil', nil]])

    assert_equal ['Weil', nil], premiere_feuille(@base).row(1).to_a
  end

  test 'setup_data ne centre que les valeurs numériques' do
    @base.add_worksheet('Feuille').add_headers(['Nom', 'Service', 'Interventions'])
    @base.setup_data([['Weil', 'Informatique', 4]])

    ligne = premiere_feuille(@base).row(1)

    assert_equal :center, ligne.format(2).horizontal_align
    assert_not_equal :center, ligne.format(1).horizontal_align
  end

  test 'build_file renvoie un binaire relu par Spreadsheet' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])

    binaire = @base.build_file

    assert_equal Encoding::BINARY, binaire.encoding
    assert_equal ['Weil'], lire_fichier_xls(binaire).worksheet(0).row(1).to_a
  end

  test 'build_file appelé deux fois renvoie le même classeur' do
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
