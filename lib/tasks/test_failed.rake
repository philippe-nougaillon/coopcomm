# frozen_string_literal: true

namespace :test do
  desc 'Rejoue les tests en échec du dernier run (test/failed_tests.rb)'
  task :failed do
    fichier = Rails.root.join('test/failed_tests.rb')
    chemins = File.exist?(fichier) ? File.readlines(fichier, chomp: true).reject(&:empty?) : []

    if chemins.empty?
      puts 'Aucun test en échec au dernier run.'
      next
    end

    puts "Rejeu de #{chemins.size} test(s) en échec :"
    chemins.each { |chemin| puts "  #{chemin}" }

    $stdout.flush # `exec` remplace le processus sans vider le tampon
    Kernel.exec(Rails.root.join('bin/rails').to_s, 'test', *chemins)
  end
end
