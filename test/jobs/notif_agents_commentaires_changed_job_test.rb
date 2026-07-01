# frozen_string_literal: true

require 'test_helper'

class NotifAgentsCommentairesChangedJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @agents       = [users(:martin_technique_paris), users(:bond)]
    @user_id      = users(:weil).id
  end

  test 'envoie un seul mail groupé aux agents et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifAgentsCommentairesChangedJob.perform_now(@intervention, @agents.map(&:id), @user_id)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal @agents.map(&:email).sort, mail.to.sort

    log = MailLog.order(:created_at).last
    assert_equal 'Nouveau commentaire', log.subject
    assert_equal @intervention.organisation.id, log.organisation_id
    assert_equal @user_id, log.user_id
    assert_equal 'mail', log.channel
    assert_equal mail.message_id, log.message_id
  end

  test 'avec un seul agent : un mail à ce seul destinataire' do
    NotifAgentsCommentairesChangedJob.perform_now(@intervention, [users(:bond).id], @user_id)

    assert_equal [users(:bond).email], ActionMailer::Base.deliveries.last.to
  end
end
