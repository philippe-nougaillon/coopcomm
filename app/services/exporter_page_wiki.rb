# frozen_string_literal: true

class ExporterPageWiki < ApplicationService
  def initialize(page)
    @page = page
  end

  def call
    fichiers = {}
    contenu = @page.contenu.body&.render_attachments(with_full_attributes: false) do |attachment|
      next attachment unless attachment.attachable.is_a?(ActiveStorage::Blob)

      repère = "fichier-#{fichiers.size}"
      fichiers[repère] = fichier(attachment.attachable)
      ActionText::Attachment.from_attributes('sgid' => repère, 'caption' => attachment.node['caption'],
                                             'presentation' => attachment.node['presentation'])
    end

    { titre: @page.titre, sous_titre: @page.sous_titre, catégorie: @page.catégorie, poids: @page.poids,
      épinglée: @page.épinglée, private: @page.private, contenu: contenu&.to_html, fichiers: fichiers,
      photo: fichier(@page.photo.blob), document: fichier(@page.document.blob) }
  end

  private

  def fichier(blob)
    blob && { filename: blob.filename.to_s, content_type: blob.content_type, data: Base64.strict_encode64(blob.download) }
  end
end
