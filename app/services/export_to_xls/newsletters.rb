# frozen_string_literal: true

module ExportToXls
  # Génère un fichier XLS des newsletters
  class Newsletters < ExportToXls::Base
    attr_reader :newsletters
    private :newsletters

    def initialize(newsletters)
      super()
      @newsletters = newsletters
    end

    def call
      headers = %w[Email Créé_le slug]

      data = []

      @newsletters.each do |newsletter|
        data << [
          newsletter.email,
          I18n.l(newsletter.created_at),
          newsletter.slug
        ]
      end

      add_worksheet('Liste des interventions')
      add_headers(headers)
      setup_data(data)
      build_file
    end
  end
end