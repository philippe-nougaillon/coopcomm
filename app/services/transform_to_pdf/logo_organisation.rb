# frozen_string_literal: true

module TransformToPdf
  # Le logo d'un en-tête de PDF : celui de l'organisation, sinon celui de CoopComm.
  class LogoOrganisation < ApplicationService
    COOPCOMM = Rails.root.join('app/assets/images/CoopComm.jpg').to_s

    def initialize(organisation)
      super()

      @organisation = organisation
    end

    # Prawn lève sur un PNG entrelacé et décode toute transparence en Ruby (plus de 600 ms par document) : d'où le JPEG sur fond blanc.
    def call
      return COOPCOMM unless @organisation&.logo&.attached?

      StringIO.new(@organisation.logo.variant(format: :jpg, resize_to_limit: [800, 400],
                                              saver: { background: 255, quality: 90 }).processed.download)
    rescue StandardError
      COOPCOMM
    end
  end
end
