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

  test 'le mail de fin d’analyse est adressé au déposant, met en copie cachée l’adresse des notifications et compte ses analyses à valider et en échec' do
    copie_initiale = ENV.fetch('BCC_NOTIFICATION_EMAILS', nil)
    ENV['BCC_NOTIFICATION_EMAILS'] = 'copie@example.com'
    deposant = users(:hidalgo)
    a_valider = Convention.where(deposant: deposant, workflow_state: Convention::ANALYSE).count

    mail = NotificationMailer.analyses_terminees(deposant)

    assert_equal [deposant.email], mail.to
    assert_equal ['copie@example.com'], mail.bcc
    assert_equal '[COOPCOMM] Analyse des conventions terminée', mail.subject
    corps = (mail.html_part || mail).body.to_s
    assert_match "#{a_valider} conventions à valider, 1 en échec.", corps.gsub(%r{</?b>}, '')
    assert_match '/conventions/analyses', corps
  ensure
    ENV['BCC_NOTIFICATION_EMAILS'] = copie_initiale
  end

  test 'le mail de fin d’analyse ne parle pas d’échec quand aucune analyse n’a échoué' do
    corps = (NotificationMailer.analyses_terminees(users(:manager_paris)).then { |mail| mail.html_part || mail }).body.to_s

    assert_no_match 'en échec', corps
  end
end
