ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'bcrypt'

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Peut servir par la suite : permet de nettoyer le cache après chaque test
    # teardown do
    #   Rails.cache.clear
    # end

    def login(user)
      visit unauthenticated_root_path
      fill_in "user_email", with: user.email
      fill_in "user_password", with: "password123" # équivalent à encrypted_password: "$2a$04$Sq0rBR0/IqysddNW29bcJO2S5vfi54HoOqWsnoEEBUDV9aajeJhUm", généré avec Devise::Encryptor.digest(User, "password123")
      click_on "Se connecter"
      sleep(1)
    end

    # Add more helper methods to be used by all tests here...
  end
end
