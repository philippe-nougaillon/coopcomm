# frozen_string_literal: true

# Rails ne valide rien par défaut sur les pièces jointes Active Storage. Ne
# valide que les nouvelles, pour ne pas bloquer les enregistrements anciens.
module PieceJointeValidable
  extend ActiveSupport::Concern

  IMAGES = %w[
    image/png
    image/jpeg
    image/jpg
    image/gif
    image/webp
    image/avif
    image/heic
    image/heif
  ].freeze

  DOCUMENTS = (%w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.oasis.opendocument.text
    application/vnd.oasis.opendocument.spreadsheet
    text/plain
    text/csv
  ] + IMAGES).freeze

  TAILLE_MAX_IMAGE = 10.megabytes
  TAILLE_MAX_DOCUMENT = 20.megabytes

  EXTENSIONS = {
    'image/png' => %w[.png],
    'image/jpeg' => %w[.jpg .jpeg],
    'image/jpg' => %w[.jpg],
    'image/gif' => %w[.gif],
    'image/webp' => %w[.webp],
    'image/avif' => %w[.avif],
    'image/heic' => %w[.heic],
    'image/heif' => %w[.heif],
    'application/pdf' => %w[.pdf],
    'application/msword' => %w[.doc],
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => %w[.docx],
    'application/vnd.ms-excel' => %w[.xls],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => %w[.xlsx],
    'application/vnd.oasis.opendocument.text' => %w[.odt],
    'application/vnd.oasis.opendocument.spreadsheet' => %w[.ods],
    'text/plain' => %w[.txt],
    'text/csv' => %w[.csv]
  }.freeze

  def self.extensions(types)
    Array(types).flat_map { |type| EXTENSIONS.fetch(type, []) }.uniq
  end

  # Extensions ET types MIME : le navigateur n'annonce pas toujours le type d'un
  # fichier, l'extension prend alors le relais.
  def self.accept(types)
    (extensions(types) + Array(types)).join(',')
  end

  def self.libellé_formats(types)
    extensions(types).map { |extension| extension.delete_prefix('.').upcase }.join(', ')
  end

  def self.libellé_taille(max_octets)
    "#{max_octets / 1.megabyte} Mo"
  end

  included do
    class_attribute :regles_pieces_jointes, instance_writer: false, default: {}
  end

  class_methods do
    def valide_image(nom)
      valide_piece_jointe(nom, types: IMAGES, max_octets: TAILLE_MAX_IMAGE)
    end

    def valide_document(nom)
      valide_piece_jointe(nom, types: DOCUMENTS, max_octets: TAILLE_MAX_DOCUMENT)
    end

    def valide_piece_jointe(nom, types:, max_octets: TAILLE_MAX_IMAGE)
      self.regles_pieces_jointes = regles_pieces_jointes.merge(nom.to_s => { types: types, max_octets: max_octets })

      validate do
        attaché = send(nom)
        nouvelles =
          if attaché.is_a?(ActiveStorage::Attached::Many)
            attaché.attachments.select(&:new_record?)
          elsif attaché.attached? && attaché.attachment.new_record?
            [attaché.attachment]
          else
            []
          end

        nouvelles.each do |piece|
          blob = piece.blob
          next if blob.nil?

          errors.add(nom, "format non pris en charge (#{blob.content_type})") unless types.include?(blob.content_type)
          errors.add(nom, "fichier trop volumineux (#{PieceJointeValidable.libellé_taille(max_octets)} maximum)") if blob.byte_size.to_i > max_octets
        end
      end
    end
  end
end
