# frozen_string_literal: true

namespace :notifications do
  desc 'Récupérer statut mail_logs dans mailgun'
  task :fetch_mailgun, [:enregistrer] => :environment do |_task, _args|
    FetchMailgunInfos.call
  end

  desc 'Récupérer statut mail_logs dans twilio'
  task :fetch_twilio, [:enregistrer] => :environment do |_task, _args|
    FetchTwilioInfos.call
  end
end
