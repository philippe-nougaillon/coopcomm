# frozen_string_literal: true

module TransformToPdf
  # Google Sans Flex, la police de l'application, embarquée dans le PDF ; DejaVu Sans prend les caractères qu'elle n'a pas.
  class Polices < ApplicationService
    FAMILLES = {
      'Google Sans Flex' => {
        normal: 'google-sans-flex/GoogleSansFlex-Regular.ttf',
        bold: 'google-sans-flex/GoogleSansFlex-Bold.ttf',
        italic: 'google-sans-flex/GoogleSansFlex-Italic.ttf',
        bold_italic: 'google-sans-flex/GoogleSansFlex-BoldItalic.ttf'
      },
      'DejaVu Sans' => {
        normal: 'dejavu-sans/DejaVuSans.ttf',
        bold: 'dejavu-sans/DejaVuSans-Bold.ttf',
        italic: 'dejavu-sans/DejaVuSans.ttf',
        bold_italic: 'dejavu-sans/DejaVuSans-Bold.ttf'
      }
    }.transform_values { |styles| styles.transform_values { |fichier| Rails.root.join('vendor/fonts', fichier).to_s } }.freeze

    def initialize(document)
      super()

      @document = document
    end

    def call
      @document.font_families.update(FAMILLES)
      @document.fallback_fonts(['DejaVu Sans'])
      @document.font('Google Sans Flex')
    end
  end
end
