# frozen_string_literal: true

# Trace dans l'audit l'ajout de pièces jointes Active Storage. Sans cela, il n'y
# a AUCUNE trace : un attachement n'est pas une colonne du modèle, donc
# `audited_changes` reste vide et audited n'écrit aucune ligne (audited-5.8.0,
# auditor.rb:355 — sur un update sans changement de colonne, une ligne n'est
# écrite que si `audit_comment` est renseigné). Le commentaire posé ici ne
# décore donc pas l'audit : c'est lui qui le fait exister.
#
# Couvre automatiquement TOUS les attachements du modèle (has_one comme
# has_many), y compris ceux qui seront ajoutés plus tard : rien à déclarer par
# pièce jointe. Ne réagit qu'aux NOUVELLES pièces jointes — le formulaire
# ré-émet les signed_id de celles déjà attachées, qui sont alors des
# enregistrements persistés (donc pas de faux « ajoutée »).
module PieceJointeAuditable
  extend ActiveSupport::Concern

  # nom de l'attachement => [singulier, pluriel] du segment de commentaire ; le
  # nombre est préfixé au rendu (« 2 photos ajoutées »).
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

  # Les reflections sont lues à l'exécution, pas à l'inclusion : le `include`
  # peut donc être placé avant les `has_one_attached` / `has_many_attached`.
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
