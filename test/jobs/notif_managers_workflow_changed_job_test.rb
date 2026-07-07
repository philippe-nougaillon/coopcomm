# frozen_string_literal: true

require 'test_helper'

class NotifManagersWorkflowChangedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @managers     = [users(:hidalgo), users(:manager_paris)]
    @user_id      = users(:weil).id
  end

  test 'envoie un mail groupé aux managers et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifManagersWorkflowChangedJob.perform_now(@intervention, @managers.map(&:id), @user_id)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal @managers.map(&:email).sort, mail.to.sort

    log = MailLog.order(:created_at).last
    assert_equal 'Changement de statut', log.subject
    assert_equal @intervention.organisation.id, log.organisation_id
    assert_equal @user_id, log.user_id
    assert_equal 'mail', log.channel
    assert_equal mail.message_id, log.message_id
  end

  test 'avec un seul manager : un mail à ce seul destinataire' do
    NotifManagersWorkflowChangedJob.perform_now(@intervention, [users(:hidalgo).id], @user_id)

    assert_equal [users(:hidalgo).email], ActionMailer::Base.deliveries.last.to
  end
end
