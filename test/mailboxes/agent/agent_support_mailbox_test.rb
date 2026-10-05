# frozen_string_literal: true

require 'test_helper'
require_relative '../../support/adresse_support'

class AgentSupportMailboxTest < ActionMailbox::TestCase
  include AdresseSupport

  test "aucune intervention n'est créée quand un agent envoie un mail au support" do
    user = users(:bond)
    subject = 'Besoin arme à feu'
    body = "Bonjour, j'ai besoin d'une arme pour ma mission"
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
