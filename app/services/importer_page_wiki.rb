# frozen_string_literal: true

class ImporterPageWiki < ApplicationService
  def initialize(page_exportée, auteur:, publiée:, origine:)
    @page_exportée = page_exportée
    @auteur = auteur
    @publiée = publiée
    @origine = origine.to_h
  end

  def call
    @blobs = []
    page = WikiPage.new(@page_exportée.slice('titre', 'sous_titre', 'catégorie', 'poids', 'épinglée', 'private'))
    page.assign_attributes(publiée: @publiée, user: @auteur, contenu: contenu&.to_html,
                           photo: pièce(@page_exportée['photo']), document: pièce(@page_exportée['document']))
    page.audit_comment = "Copiée depuis #{@origine['instance']}, page #{@origine['slug']}, par #{@origine['par']}"
    page.save!
    page
  rescue ActiveRecord::RecordInvalid
    @blobs.each(&:purge)
    raise
  end

  private

  def contenu
    fichiers = @page_exportée['fichiers'].to_h
    ActionText::Content.new(@page_exportée['contenu']).render_attachments(with_full_attributes: false) do |attachment|
      fichier = fichiers[attachment.node['sgid']]
      next attachment unless fichier

      blob = ActiveStorage::Blob.create_and_upload!(**pièce(fichier))
      @blobs << blob
      ActionText::Attachment.from_attachable(blob, caption: attachment.node['caption'],
                                                   presentation: attachment.node['presentation'],
                                                   url: Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true))
    end
  end

  def pièce(fichier)
    fichier && { io: StringIO.new(Base64.strict_decode64(fichier['data'])), filename: fichier['filename'],
                 content_type: fichier['content_type'] }
  end
end
