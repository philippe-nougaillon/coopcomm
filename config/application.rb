# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Coopcomm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
    config.i18n.fallbacks = [:en]

    config.active_record.use_yaml_unsafe_load = true

    # Mission Control's controllers will extend the host app's ApplicationController.
    # If no authentication is enforced, /jobs will be available to everyone.
    # You might want to implement some kind of authentication for this in your app.
    # To make this easier, you can specify a different controller as the base class
    config.mission_control.jobs.base_controller_class = 'MissionControlAdminController'

    config.active_support.to_time_preserves_timezone = :zone

    # config/application.rb
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.yml')]
  end
end
