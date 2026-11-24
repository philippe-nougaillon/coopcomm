# frozen_string_literal: true

require 'prawn'

# Fabrique de PDF pour les tests de lecture de document : avec une couche de texte, ou fait d'images seules
# comme une numérisation.
module FabriquePdf
  def pdf_de_texte(pages)
    fichier_pdf do |pdf|
      pages.each_with_index do |texte, rang|
        pdf.start_new_page if rang.positive?
        pdf.text texte
      end
    end
  end

  def pdf_numerise(pages)
    fichier_pdf do |pdf|
      pages.times do |rang|
        pdf.start_new_page if rang.positive?
        pdf.image file_fixture('page_numerisee.png').to_s, fit: [400, 400]
      end
    end
  end

  def pdf_numerise_avec_texte(texte)
    image = Tempfile.new(['page', '.png'])
    system('pdftoppm', '-r', '150', '-png', '-singlefile', pdf_de_texte([texte]), image.path.delete_suffix('.png'), exception: true)
    @pdf << image

    fichier_pdf { |pdf| pdf.image image.path, fit: [540, 720] }
  end

  def fermer_pdf
    Array(@pdf).each(&:close!)
  end

  private

  def fichier_pdf(&)
    tempfile = Tempfile.new(['convention', '.pdf'])
    Prawn::Fonts::AFM.hide_m17n_warning = true
    Prawn::Document.generate(tempfile.path, &)
    (@pdf ||= []) << tempfile

    tempfile.path
  end
end
