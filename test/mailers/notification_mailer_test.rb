# frozen_string_literal: true

require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  test 'le mail de cotation envoyée est adressé au destinataire, met en copie son émetteur, cite la référence de la cotation et joint son PDF' do
    cotation = cotations(:cotation_paris)
    mail = NotificationMailer.cotation_envoyee(cotation, 'client@example.com', 'emetteur@example.com')

    assert_equal ['client@example.com'], mail.to
    assert_equal ['emetteur@example.com'], mail.cc
    assert_equal '[COOPCOMM] Votre cotation', mail.subject

    body = (mail.html_part || mail).body.to_s
    assert_match cotation.ref, body

    assert_equal 1, mail.attachments.size
    attachment = mail.attachments.first
    assert_equal cotation.pdf_filename, attachment.filename
    assert_equal 'application/pdf', attachment.mime_type
  end

  test 'le mail de cotation envoyée ne met personne en copie sans adresse de copie' do
    cotation = cotations(:cotation_paris)
    mail = NotificationMailer.cotation_envoyee(cotation, 'client@example.com')

    assert_nil mail.cc
  end

  test 'le mail de bienvenue à l’inscription part de MAIL_FROM vers l’inscrit, le salue par son prénom et mène à la connexion' do
    inscrit = users(:administrateur_paris)
    mail = NotificationMailer.welcome_inscription(inscrit)

    assert_equal ENV.fetch('MAIL_FROM'), mail[:from].value
    assert_equal [inscrit.email], mail.to
    assert_equal '[COOPCOMM] Bienvenue !', mail.subject

    corps = Nokogiri::HTML((mail.html_part || mail).body.to_s).at_css('.email-body')
    assert_equal 'Bienvenue Paris !', corps.at_css('h2').text.squish
    assert_equal 'http://www.example.com/users/sign_in', corps.at_css('a')['href']
  end
end
