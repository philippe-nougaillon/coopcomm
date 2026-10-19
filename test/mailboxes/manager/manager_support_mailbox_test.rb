# frozen_string_literal: true

require 'test_helper'
require_relative '../../support/adresse_support'

class ManagerSupportMailboxTest < ActionMailbox::TestCase
  include AdresseSupport

  test "aucune intervention n'est créée quand un manager envoie un mail au support" do
    user = users(:hidalgo)
    subject = 'Dératiser ma ville'
    body = "Bonjour, serait-il possible de dératiser Paris, tout le monde s'en plaint"

    assert_no_changes -> { Intervention.count } do
      receive_inbound_email_from_mail(
        to: ADRESSE_SUPPORT,
        from: user.email,
        subject: subject,
        body: body,
        charset: 'UTF-8'
      )
    end
  end
end
