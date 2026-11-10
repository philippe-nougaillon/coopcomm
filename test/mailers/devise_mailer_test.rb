# frozen_string_literal: true

require 'test_helper'

class DeviseMailerTest < ActionMailer::TestCase
  setup do
    Rails.application.reload_routes_unless_loaded
  end

  test 'le mail de confirmation ne porte qu’un lien, celui qui confirme le compte par son jeton' do
    mail = Devise::Mailer.confirmation_instructions(User.new(email: 'jeanne.dupont@exemple.fr'), 'jeton')

    liens = Nokogiri::HTML(mail.body.to_s).css('a').map { |lien| lien['href'] }

    assert_equal ['http://www.example.com/users/confirmation?confirmation_token=jeton'], liens
  end

  test 'le mail de confirmation ne reprend pas le prénom saisi à l’inscription, l’adresse n’étant pas encore prouvée' do
    inscrit = User.new(email: 'jeanne.dupont@exemple.fr', prénom: 'Gagnez 1000 euros')

    assert_no_match 'Gagnez 1000 euros', Devise::Mailer.confirmation_instructions(inscrit, 'jeton').body.to_s
  end
end
