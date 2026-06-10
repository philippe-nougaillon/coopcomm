# frozen_string_literal: true

require 'test_helper'

class ManagerSupportMailboxTest < ActionMailbox::TestCase
  test 'Créer une intervention quand un manager envoie un mail au support' do
    user = users(:hidalgo)
    subject = 'Dératiser ma ville'
    body = "Bonjour, serait-il possible de dératiser Paris, tout le monde s'en plaint"

    assert_no_changes -> { Intervention.count } do
      receive_inbound_email_from_mail(
        to: 'support@mg.coopcom.fr',
        from: user.email,
        subject: subject,
        body: body,
        charset: 'UTF-8'
      )
    end
  end
end
