# frozen_string_literal: true

module Minitest
  FICHIER_TESTS_ECHOUES = File.expand_path('failed_tests.rb', __dir__)

  class FailedTestsReporter < AbstractReporter
    def initialize(fichier)
      super()
      @fichier = fichier
      @échecs = []
    end

    # Un run interrompu ne passe jamais par `report` : sans ce vidage, on
    # relirait la liste du run précédent en la croyant fraîche.
    def start
      File.write(@fichier, '')
    end

    def record(result)
      return if result.passed? || result.skipped?

      fichier, ligne = result.source_location
      @échecs << "#{chemin_relatif(fichier)}:#{ligne}"
    end

    def report
      lignes = @échecs.uniq.sort
      File.write(@fichier, lignes.empty? ? '' : "#{lignes.join("\n")}\n")
    end

    private

    def chemin_relatif(chemin)
      Pathname.new(File.expand_path(chemin)).relative_path_from(Rails.root).to_s
    rescue ArgumentError
      chemin
    end
  end

  def self.plugin_failed_tests_init(_options)
    reporter << FailedTestsReporter.new(FICHIER_TESTS_ECHOUES)
  end
end

Minitest.register_plugin 'failed_tests'
