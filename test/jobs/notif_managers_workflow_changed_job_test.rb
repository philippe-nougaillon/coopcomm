# frozen_string_literal: true

require 'test_helper'

class NotifManagersWorkflowChangedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @managers     = [users(:hidalgo), users(:manager_paris)]
    @user_id      = users(:weil).id
  end

  test 'les managers reçoivent un seul mail groupé et un mail log est créé lorsque le statut d’une intervention change' do
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

  test 'un manager seul est l’unique destinataire du mail' do
    NotifManagersWorkflowChangedJob.perform_now(@intervention, [users(:hidalgo).id], @user_id)

    assert_equal [users(:hidalgo).email], ActionMailer::Base.deliveries.last.to
  end

  test 'un mail log sans auteur est attribué au Système' do
    assert_difference -> { MailLog.where(user_id: 0).count }, 1 do
      NotifManagersWorkflowChangedJob.perform_now(@intervention, @managers.map(&:id), nil)
    end
  end
end
