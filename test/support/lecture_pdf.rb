# frozen_string_literal: true

# Relit le texte d'un PDF produit par Prawn, pour asserter son contenu plutôt
# que son seul type MIME.
#
# Prawn n'active pas la compression : le texte est écrit en chaînes
# hexadécimales Windows-1252 dans les blocs `BT…ET`. Le crénage coupe un mot en
# plusieurs chaînes AU SEIN d'un même bloc — d'où la concaténation sans
# séparateur à l'intérieur d'un bloc, et l'espace entre deux blocs.
module LecturePdf
  ESPACE_INSECABLE = "\u00A0"
  # Dimensions en pixels de test/fixtures/files/logo_organisation.png et du repli de TransformToPdf::LogoOrganisation.
  DIMENSIONS_LOGO_ORGANISATION = [60, 30].freeze
  DIMENSIONS_LOGO_COOPCOMM = [800, 153].freeze

  def texte_pdf(document)
    octets = document.respond_to?(:render) ? document.render : document

    blocs = octets.dup.force_encoding(Encoding::BINARY).scan(/BT(.*?)ET/m).map do |(bloc)|
      bloc.scan(/<([0-9A-Fa-f]+)>/).map { |(hex)| [hex].pack('H*') }.join
    end

    blocs.join(' ')
         .force_encoding('Windows-1252')
         .encode('UTF-8')
         .tr(ESPACE_INSECABLE, ' ')
         .squeeze(' ')
         .strip
  end

  # [largeur, hauteur] en pixels de chaque image : Prawn écrit son dictionnaire en clair, clés triées.
  def dimensions_images_pdf(document)
    document.render.dup.force_encoding(Encoding::BINARY)
            .scan(%r{/Height (\d+)\s+/Length \d+\s+(?:/SMask \d+ 0 R\s+)?/Subtype /Image\s+/Type /XObject\s+/Width (\d+)})
            .map { |hauteur, largeur| [largeur.to_i, hauteur.to_i] }
  end

  # [largeur, hauteur] en points de chaque image dessinée, lues dans l'opérateur `cm` qui précède `Do`.
  def tailles_images_pdf(document)
    document.render.dup.force_encoding(Encoding::BINARY)
            .scan(%r{([\d.]+) 0\.0+ 0\.0+ ([\d.]+) [\d.]+ [\d.]+ cm\s+/I\d+ Do}).map { |taille| taille.map(&:to_f) }
  end
end
