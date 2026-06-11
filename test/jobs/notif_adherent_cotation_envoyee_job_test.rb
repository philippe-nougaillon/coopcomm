# frozen_string_literal: true

require 'test_helper'

class NotifAdherentCotationEnvoyeeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @cotation = cotations(:cotation_paris)
    @adherent = @cotation.adherent
    @sender   = users(:administrateur_paris)
  end

  test 'envoie un mail à l\'adhérent et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentCotationEnvoyeeJob.perform_now(@cotation, @adherent, @sender.id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    # Le sujet tracé doit être identique à celui réellement envoyé (source unique).
    assert_equal ActionMailer::Base.deliveries.last.subject, log.subject
    assert_equal @cotation.organisation.id, log.organisation_id
    assert_equal @sender.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test 'met l\'émetteur en copie du mail' do
    NotifAdherentCotationEnvoyeeJob.perform_now(@cotation, @adherent, @sender.id)

    assert_equal [@sender.email], ActionMailer::Base.deliveries.last.cc
  end
end
