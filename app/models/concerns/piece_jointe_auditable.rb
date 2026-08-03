# frozen_string_literal: true

# Un attachement n'étant pas une colonne, audited n'écrit une ligne que si
# `audit_comment` est renseigné : le commentaire posé ici fait exister l'audit.
module PieceJointeAuditable
  extend ActiveSupport::Concern

  # nom de l'attachement => [singulier, pluriel]
  LIBELLES = {
    'photo' => ['photo ajoutée', 'photos ajoutées'],
    'photos' => ['photo ajoutée', 'photos ajoutées'],
    'profile_picture' => ['photo de profil ajoutée', 'photos de profil ajoutées'],
    'document' => ['document ajouté', 'documents ajoutés'],
    'documents' => ['document ajouté', 'documents ajoutés'],
    'fichier' => ['fichier ajouté', 'fichiers ajoutés']
  }.freeze

  included do
    before_save :audite_pieces_jointes_ajoutees
  end

  private

  def audite_pieces_jointes_ajoutees
    ajouts = pieces_jointes_ajoutees
    return if ajouts.empty?

    self.audit_comment = ajouts.map { |nom, nombre| libelle_piece_jointe(nom, nombre) }.join(', ')
  end

  def pieces_jointes_ajoutees
    self.class.attachment_reflections.keys.filter_map do |nom|
      attaché = send(nom)
      pieces = attaché.is_a?(ActiveStorage::Attached::Many) ? attaché.attachments : [attaché.attachment]
      nombre = pieces.compact.count(&:new_record?)

      [nom, nombre] if nombre.positive?
    end
  end

  def libelle_piece_jointe(nom, nombre)
    defaut = ["#{nom.to_s.humanize.downcase} ajouté", "#{nom.to_s.humanize.downcase}s ajoutés"]
    singulier, pluriel = LIBELLES.fetch(nom.to_s, defaut)

    "#{nombre} #{nombre > 1 ? pluriel : singulier}"
  end
end
