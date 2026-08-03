# frozen_string_literal: true

module TransformToPdf
  class Facture < BasePdf
    private

    def document_title
      'Facture'
    end

    def document_lignes_association
      :facture_lignes
    end
  end
end