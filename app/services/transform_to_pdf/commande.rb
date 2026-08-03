# frozen_string_literal: true

module TransformToPdf
  class Commande < BasePdf
    private

    def document_title
      'Commande'
    end

    def document_lignes_association
      :commande_lignes
    end
  end
end