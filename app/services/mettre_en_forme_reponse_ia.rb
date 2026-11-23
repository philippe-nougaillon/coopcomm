# frozen_string_literal: true

# Rend le markdown écrit par un modèle de langage : jamais son HTML, ni image, ni lien.
class MettreEnFormeReponseIa < ApplicationService
  BALISES = %w[p br strong em del h1 h2 h3 h4 h5 h6 ul ol li hr blockquote code pre table thead tbody tr th td].freeze
  EXTENSIONS = { lax_spacing: true, no_intra_emphasis: true, tables: true, fenced_code_blocks: true, strikethrough: true }.freeze

  def initialize(texte, texte_seul: false)
    @texte = texte
    @texte_seul = texte_seul
  end

  def call
    rendu = Redcarpet::Render::HTML.new(escape_html: true, no_images: true, no_links: true, hard_wrap: true)
    # Un trait collé sous une ligne de texte en ferait un titre.
    html = Redcarpet::Markdown.new(rendu, EXTENSIONS).render(@texte.gsub(/(?:^-{3,}[ \t]*(?:\n|\z))+/, "\n---\n"))
    html = ActionController::Base.helpers.sanitize(html, tags: BALISES, attributes: [])

    @texte_seul ? Nokogiri::HTML5.fragment(html).text.squish : html
  end
end
