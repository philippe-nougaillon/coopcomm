# frozen_string_literal: true

module TransformToPdf
  class Cotation < BasePdfForCrm 
    private

    def document_title
      'Cotation / Devis'
    end

    def document_lignes_association
      :cotation_lignes
    end
  end
end