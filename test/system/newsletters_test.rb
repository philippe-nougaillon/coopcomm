# frozen_string_literal: true

require 'application_system_test_case'

class NewslettersTest < ApplicationSystemTestCase
  test "inscription à la newsletter depuis la page d'accueil publique" do
    visit root_url
    # Filet anti-flake (cf. test_helper#login)
    visit root_url unless page.has_css?('#newsletter_form_email', wait: 5)

    fill_in 'newsletter_form_email', with: 'nouvel.inscrit@exemple.fr'
    click_on "JE M'INSCRIS"

    assert_text 'Votre inscription a bien été effectuée.'
    assert Newsletter.exists?(email: 'nouvel.inscrit@exemple.fr')
  end

  test 'la liste des inscrits est réservée au super admin' do
    ancien = ENV['SUPER_ADMIN']
    ENV['SUPER_ADMIN'] = users(:hidalgo).email
    login(users(:hidalgo))

    visit newsletters_url

    assert_selector 'h1', text: 'Newsletters'
    assert_text newsletters(:bond).email
  ensure
    ENV['SUPER_ADMIN'] = ancien
  end
end
