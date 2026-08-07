# frozen_string_literal: true

require 'spreadsheet'

# Fabrique de classeurs Excel 97-2003 pour les tests d'import.
#
# Chaque test construit son propre fichier : la fixture `files/import_users.xls`
# reste réservée au test de non-régression sécurité (aucune copie dans public/).
module FabriqueXls
  ENTETES = %w[Nom Prénom Email Téléphone Service Mémo].freeze

  # Une ligne dans l'ordre d'ENTETES.
  def ligne(nom:, prénom:, email:, service: 'Informatique', téléphone: nil, mémo: nil)
    [nom, prénom, email, téléphone, service, mémo]
  end

  def fichier_xls(lignes)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    feuille = book.create_worksheet(name: 'Import')
    lignes.each_with_index { |ligne, index| feuille.row(index).replace(ligne) }

    tempfile = Tempfile.new(['import', '.xls'])
    book.write(tempfile.path)
    (@tempfiles ||= []) << tempfile

    tempfile
  end

  def televersement(lignes)
    Rack::Test::UploadedFile.new(fichier_xls(lignes).path, 'application/vnd.ms-excel')
  end

  # Fichier portant l'extension .xls mais dont le contenu n'en est pas un.
  def fichier_illisible(contenu = 'ceci n’est pas un classeur')
    tempfile = Tempfile.new(['faux', '.xls'])
    tempfile.write(contenu)
    tempfile.flush
    (@tempfiles ||= []) << tempfile

    tempfile
  end

  def fermer_fichiers
    Array(@tempfiles).each(&:close!)
  end
end
