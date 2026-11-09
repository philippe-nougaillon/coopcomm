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
end
