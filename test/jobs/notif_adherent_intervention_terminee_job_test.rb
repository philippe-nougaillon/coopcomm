# frozen_string_literal: true

require 'test_helper'

class NotifAdherentInterventionTermineeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil)
    @user_id      = users(:administrateur_paris).id
  end

  test 'envoie un mail à l\'adhérent et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAdherentInterventionTermineeJob.perform_now(@intervention, @adherent, @user_id)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    assert_equal 'Intervention terminée', log.subject
    assert_equal @intervention.organisation.id, log.organisation_id
    assert_equal @user_id, log.user_id
    assert_equal 'mail', log.channel
    assert_equal ActionMailer::Base.deliveries.last.message_id, log.message_id
  end

  test 'le mail part bien vers l\'adresse de l\'adhérent' do
    NotifAdherentInterventionTermineeJob.perform_now(@intervention, @adherent, @user_id)

    assert_equal [@adherent.email], ActionMailer::Base.deliveries.last.to
  end
end
