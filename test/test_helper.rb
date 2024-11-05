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

    setup do
    #   mairie_paris = organisations(:mairie_paris)
      # @manager = mairie_paris.users.create(prénom: "Manon", email: 'manager@gmail.commmm', rôle: 'manager', password: 'azeaze', password_confirmation: 'azeaze')
      @manager = users(:hidalgo)
    #   # @adhérent = mairie_paris.users.create(prénom: "Ulysse", email: 'ulysse@gmail.commm', rôle: 'adhérent', password: '@wGheRSJikuM2ng', password_confirmation: '@wGheRSJikuM2ng')
    #   @agent = mairie_paris.users.create(prénom: "Agénor", email: 'agenor@gmail.commm', rôle: 'agent', service: 'informatique', password: '5bc323c18b587678b6b9', password_confirmation: '5bc323c18b587678b6b9')
      @agent = users(:bond)
    end

    def login(user)
      visit unauthenticated_root_path
      fill_in "user_email", with: user.email
      fill_in "user_password", with: "password123" # équivalent à encrypted_password: "$2a$04$Sq0rBR0/IqysddNW29bcJO2S5vfi54HoOqWsnoEEBUDV9aajeJhUm", généré avec Devise::Encryptor.digest(User, "password123")
      click_on "Se connecter"
      sleep(1)
    end

    # def js_select(item_text, options)
    #   container = find(:xpath, "//parent::*[label[text()='#{options[:from]}']]")
    #   within "##{container[:id]}", visible: false do
    #     find('.ss-arrow').click
    #     input = find(".ss-search input").native
    #     input.send_keys(item_text)
    #     find('div.ss-list').click
    #   end
    # end

    # Add more helper methods to be used by all tests here...
  end
end
