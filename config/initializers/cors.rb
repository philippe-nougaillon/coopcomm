# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

# Origines autorisées via APP_CORS_ORIGINS (liste séparée par des virgules).
# Sans la variable, aucune origine étrangère n'est admise — le front est servi
# par le même domaine (monolithe importmap), il n'a pas besoin de CORS.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('APP_CORS_ORIGINS', '').split(',').map(&:strip)
    resource '/rails/active_storage/*',
             headers: :any,
             methods: %i[get post put delete options]
  end
end
