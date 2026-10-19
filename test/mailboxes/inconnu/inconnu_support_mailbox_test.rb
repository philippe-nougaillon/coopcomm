# frozen_string_literal: true

require 'test_helper'
require_relative '../../support/adresse_support'

class InconnuSupportMailboxTest < ActionMailbox::TestCase
  include AdresseSupport

  test "aucune intervention n'est créée quand un inconnu envoie un mail au support" do
    subject = 'Nids de poule'
    body = 'Rebouchez les nids de poule svp'
    assert_no_changes -> { Intervention.count } do
      receive_inbound_email_from_mail(
        to: ADRESSE_SUPPORT,
        from: 'inconnu@gmail.commm',
        subject: subject,
        body: body,
        charset: 'UTF-8'
      )
    end
  end
end
