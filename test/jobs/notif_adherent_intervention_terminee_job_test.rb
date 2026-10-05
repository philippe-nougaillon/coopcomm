# frozen_string_literal: true

require 'test_helper'

class NotifAdherentInterventionTermineeJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil)
    @user_id      = users(:administrateur_paris).id
  end

  test 'l’adhérent reçoit un mail et un mail log est créé lorsque son intervention est terminée' do
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

  test 'le mail est adressé à l’adhérent de l’intervention' do
    NotifAdherentInterventionTermineeJob.perform_now(@intervention, @adherent, @user_id)

    assert_equal [@adherent.email], ActionMailer::Base.deliveries.last.to
  end

  test 'un mail log sans auteur est attribué au Système' do
    assert_difference -> { MailLog.where(user_id: 0).count }, 1 do
      NotifAdherentInterventionTermineeJob.perform_now(@intervention, @adherent, nil)
    end
  end
end
