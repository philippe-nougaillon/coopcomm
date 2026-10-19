# frozen_string_literal: true

require 'test_helper'

class NotifAibboRequestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    request_message = messages(:one)
    response_message = Message.create!(message: 'Réponse', from_id: users(:bond).id, to_id: users(:hidalgo).id)
    @aibot_log = AibotLog.create!(user: users(:hidalgo), request_message: request_message, response_message: response_message,
                                  succes: true, log_stream: "<b>Log</b>\n\e[1m\e[32mvert gras\e[0m neutre")
    @previous_bcc = ENV['BCC_NOTIFICATION_EMAILS']
    ENV['BCC_NOTIFICATION_EMAILS'] = 'admin-systeme@example.com'
  end

  teardown do
    ENV['BCC_NOTIFICATION_EMAILS'] = @previous_bcc
  end

  test 'une requête AIBOT est envoyée par mail aux administrateurs' do
    assert_emails 1 do
      NotifAibboRequestJob.perform_now(@aibot_log)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ['admin-systeme@example.com'], mail.to
    assert_equal '[COOPCOMM] Requête AIBOT', mail.subject
  end

  test 'le mail nomme l’auteur de la demande, son rôle, et affiche sa demande' do
    NotifAibboRequestJob.perform_now(@aibot_log)

    body = (ActionMailer::Base.deliveries.last.html_part || ActionMailer::Base.deliveries.last).body.to_s
    assert_includes body, "Demande de #{users(:hidalgo).nom_prénom} (#{users(:hidalgo).rôle})"
    assert_includes body, '>Salut !</p>'
  end

  test 'le mail affiche le log AIBOT sans ses codes couleur ANSI' do
    NotifAibboRequestJob.perform_now(@aibot_log)

    body = (ActionMailer::Base.deliveries.last.html_part || ActionMailer::Base.deliveries.last).body.to_s
    assert_includes body, ">&lt;b&gt;Log&lt;/b&gt;\nvert gras neutre</p>"
  end

  test 'le mail renvoie vers la page du log AIBOT' do
    NotifAibboRequestJob.perform_now(@aibot_log)

    body = (ActionMailer::Base.deliveries.last.html_part || ActionMailer::Base.deliveries.last).body.to_s
    assert_includes body, "href=\"http://www.example.com/aibot_logs/#{@aibot_log.slug}\""
  end
end
