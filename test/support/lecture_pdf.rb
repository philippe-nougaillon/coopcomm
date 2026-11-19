# frozen_string_literal: true

require 'pdf/reader'

# Relit le texte d'un PDF produit par Prawn, pour asserter son contenu plutôt
# que son seul type MIME. Les retours à la ligne et l'espace insécable y
# deviennent des espaces simples.
module LecturePdf
  ESPACE_INSECABLE = "\u00A0"

  def texte_pdf(document)
    octets = document.respond_to?(:render) ? document.render : document

    PDF::Reader.new(StringIO.new(octets)).pages.map(&:text).join(' ')
               .tr(ESPACE_INSECABLE, ' ')
               .gsub(/\s+/, ' ')
               .strip
  end
end
