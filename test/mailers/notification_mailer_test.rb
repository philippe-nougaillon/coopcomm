# frozen_string_literal: true

require 'test_helper'

class NotificationMailerTest < ActionMailer::TestCase
  test 'cotation_envoyee : destinataire, copie, sujet, corps et PDF en pièce jointe' do
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

  test 'cotation_envoyee : aucune copie quand cc_email est absent' do
    cotation = cotations(:cotation_paris)
    mail = NotificationMailer.cotation_envoyee(cotation, 'client@example.com')

    assert_nil mail.cc
  end
end
