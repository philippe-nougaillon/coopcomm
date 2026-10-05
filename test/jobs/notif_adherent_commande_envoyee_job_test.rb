# frozen_string_literal: true

require 'test_helper'

class NotifAdherentCommandeEnvoyeeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @commande = commandes(:commande_paris)
    @adherent = @commande.adherent
    @sender   = users(:administrateur_paris)
  end

  test "l'adhérent reçoit un mail et un mail log est créé lorsque sa commande est envoyée" do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentCommandeEnvoyeeJob.perform_now(@commande, @adherent, @sender.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    # Le sujet tracé doit être identique à celui réellement envoyé (source unique).
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @commande.organisation.id, log.organisation_id
    assert_equal @sender.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test "l'émetteur est mis en copie du mail" do
    NotifAdherentCommandeEnvoyeeJob.perform_now(@commande, @adherent, @sender.id)

    assert_equal [@sender.email], ActionMailer::Base.deliveries.last.cc
  end
end
