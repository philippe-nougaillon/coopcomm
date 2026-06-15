# frozen_string_literal: true

# Validation de type et de taille des pièces jointes Active Storage — Rails ne
# valide rien par défaut : sans cela, n'importe quel fichier (HTML, exécutable…)
# peut être stocké puis servi. Ne valide que les NOUVELLES pièces jointes, pour
# ne pas bloquer la modification d'enregistrements anciens.
module PieceJointeValidable
  extend ActiveSupport::Concern

  IMAGES = %w[image/png image/jpeg image/gif image/webp image/heic image/heif].freeze
  DOCUMENTS = (IMAGES + %w[application/pdf]).freeze

  class_methods do
    def valide_piece_jointe(nom, types:, max_octets: 10.megabytes)
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
          errors.add(nom, "fichier trop volumineux (#{max_octets / 1.megabyte} Mo maximum)") if blob.byte_size.to_i > max_octets
        end
      end
    end
  end
end
