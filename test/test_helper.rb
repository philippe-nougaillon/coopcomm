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

    def login(user)
      visit unauthenticated_root_path
      fill_in "user_email", with: user.email
      fill_in "user_password", with: "password123" # équivalent à encrypted_password: "$2a$04$Sq0rBR0/IqysddNW29bcJO2S5vfi54HoOqWsnoEEBUDV9aajeJhUm", généré avec Devise::Encryptor.digest(User, "password123")
      click_on "Se connecter"
      sleep(1)
    end

    def js_select(item_text, options)
      container = find(:xpath, "//parent::*[label[text()='#{options[:from]}']]")
      puts "aaaaa"
      puts container
      puts "bb"
      puts container.inspect
      puts "cc"
      within "##{container[:id]}", visible: false do
        puts "dd"
        find('.ss-arrow').click
        input = find(".ss-search input").native
        input.send_keys(item_text)
        find('div.ss-list').click
      end
    end

    def select_from_slim_select(item_text, options)
      from = options.fetch(:from)
      puts "aa"
      puts from
      puts "bb"

      if !from.include?("#")
        label = find("label", text: from)
        from = "##{label["for"]}"
      end

      puts label.inspect
      puts from
      puts "cc"

      select_field = find(from, visible: false, wait: 2)
      puts select_field.inspect
      puts "dd"
      slim_select_id = select_field["data-ssid"]
      puts slim_select_id
      puts "ee"
      slim_select_container = find("div.#{slim_select_id}")

      within(slim_select_container) do
        find(".ss-arrow, .ss-add").click

        sleep(0.5)

        input = find(".ss-search input").native
        input.send_keys(item_text)
        find("div.ss-list").click
      end

      click_off
      expect_ss_list_to_not_be_visible
    end

    def expect_ss_list_to_be_visible
      expect(page).to have_css("div.ss-list")
    end

    def expect_ss_list_to_not_be_visible
      expect(page).to_not have_css("div.ss-list")
    end

    def click_off
      page.execute_script('document.querySelector("body").click();')
    end

    # Add more helper methods to be used by all tests here...
  end
end
