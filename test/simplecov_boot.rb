# frozen_string_literal: true

# Désactiver SimpleCov en CI (couverture non nécessaire, cause des problèmes)
return if ENV['CI'].present?

require 'simplecov'

# Tout fichier chargé avant `SimpleCov.start` est invisible pour Coverage et
# rapporté à 0 %. `rails test:all` boote l'application avant les tests : ce
# fichier doit donc être préchargé (`bin/coverage`) pour mesurer le boot.
unless SimpleCov.running
  SimpleCov.start 'rails' do
    add_group 'Components', 'app/components'
    add_group 'Mailboxes', 'app/mailboxes'
    add_group 'Policies', 'app/policies'
    add_group 'PDFs', 'app/pdfs'
    add_group 'Services', 'app/services'
    add_group 'Subscriptions', 'app/subscriptions'
  end
end
