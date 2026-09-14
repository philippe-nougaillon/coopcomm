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
end
