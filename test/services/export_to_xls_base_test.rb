# frozen_string_literal: true

require 'test_helper'

# Classe mère des cinq exports XLS. Elle n'a pas de `call` : ses méthodes se
# testent directement, aucun export ne pouvant les atteindre autrement.
class ExportToXlsBaseTest < ActiveSupport::TestCase
  setup do
    @base = ExportToXls::Base.new
  end

  test 'add_worksheet : un nom → la feuille est créée et le service est renvoyé pour le chaînage' do
    retour = @base.add_worksheet('Liste des agents')

    assert_same @base, retour
    assert_equal ['Liste des agents'], lire(@base.build_file).worksheets.map(&:name)
  end

  test 'add_worksheet : deux appels → deux feuilles dans l’ordre de création' do
    @base.add_worksheet('Première').add_worksheet('Seconde')

    assert_equal %w[Première Seconde], lire(@base.build_file).worksheets.map(&:name)
  end

  test 'add_headers : trois en-têtes → la première ligne les porte' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom Email])

    assert_equal %w[Nom Prénom Email], feuille(@base).row(0).to_a
  end

  test 'setup_data : trois lignes → le classeur en compte quatre avec l’en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([%w[Weil Ariel], %w[Bond James], %w[Martin Michel]])

    assert_equal 4, feuille(@base).rows.count
    assert_equal %w[Weil Ariel], feuille(@base).row(1).to_a
    assert_equal %w[Martin Michel], feuille(@base).row(3).to_a
  end

  test 'setup_data : aucune ligne → le classeur ne porte que son en-tête' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Prénom])
    @base.setup_data([])

    assert_equal 1, feuille(@base).rows.count
  end

  test 'setup_data : une cellule nulle → la ligne est écrite sans lever' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom Téléphone])
    @base.setup_data([['Weil', nil]])

    assert_equal ['Weil', nil], feuille(@base).row(1).to_a
  end

  test 'setup_data : un nombre et un texte → seul le nombre est centré' do
    @base.add_worksheet('Feuille').add_headers(['Nom', 'Service', 'Interventions'])
    @base.setup_data([['Weil', 'Informatique', 4]])

    ligne = feuille(@base).row(1)

    assert_equal :center, ligne.format(2).horizontal_align
    assert_not_equal :center, ligne.format(1).horizontal_align
  end

  test 'build_file : un classeur rempli → un binaire relu par Spreadsheet' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])

    binaire = @base.build_file

    assert_equal Encoding::BINARY, binaire.encoding
    assert_equal ['Weil'], lire(binaire).worksheet(0).row(1).to_a
  end

  test 'build_file : deux appels successifs → le second classeur est identique au premier' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])

    assert_equal @base.build_file, @base.build_file
  end

  test 'autofit_columns_with_gap : une cellule longue → la colonne prend sa longueur plus quatre' do
    description = 'Tonte des espaces verts du centre-bourg'
    @base.add_worksheet('Feuille').add_headers(['Description'])
    @base.setup_data([[description]])
    @base.build_file

    assert_equal description.length + 4, feuille(@base).column(0).width
  end

  test 'autofit_columns_with_gap : un en-tête plus long que ses données → la colonne suit l’en-tête' do
    @base.add_worksheet('Feuille').add_headers(["Nombre d'interventions"])
    @base.setup_data([[4]])
    @base.build_file

    assert_equal "Nombre d'interventions".length + 4, feuille(@base).column(0).width
  end

  test 'autofit_columns_with_gap : des cellules courtes → la colonne garde la largeur minimale' do
    @base.add_worksheet('Feuille').add_headers(%w[Nom])
    @base.setup_data([['Weil']])
    @base.build_file

    assert_equal 10, feuille(@base).column(0).width
  end

  private

  def feuille(service)
    lire(service.build_file).worksheet(0)
  end

  def lire(binaire)
    Spreadsheet.open(StringIO.new(binaire))
  end
end
