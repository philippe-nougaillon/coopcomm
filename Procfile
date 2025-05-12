web: bundle exec puma -C config/puma.rb
worker: bundle exec rake solid_queue:start
release: bundle exec rake db:migrate