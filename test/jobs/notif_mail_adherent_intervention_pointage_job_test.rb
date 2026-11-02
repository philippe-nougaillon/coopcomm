# frozen_string_literal: true

require 'test_helper'

class NotifMailAdherentInterventionPointageJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # tonte_locaux porte un adherent_id (weil), une organisation (via service)
    # et un agent (bond).
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil)
    @agent        = users(:bond)
  end

  test "l'adhérent reçoit un mail et un mail log est créé lorsque son intervention est pointée" do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifMailAdherentInterventionPointageJob.perform_now(@intervention)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    assert_equal 'Intervention pointage', log.subject
    assert_equal @intervention.organisation.id, log.organisation_id
    # L'émetteur tracé est l'agent qui a pointé (agent de l'intervention).
    assert_equal @agent.id, log.user_id
    assert_equal 'mail', log.channel
    assert_equal ActionMailer::Base.deliveries.last.message_id, log.message_id
  end

  test "le mail est adressé à l'adhérent de l'intervention" do
    NotifMailAdherentInterventionPointageJob.perform_now(@intervention)

    assert_equal [@adherent.email], ActionMailer::Base.deliveries.last.to
  end

  test 'une intervention sans adhérent fait échouer le job (User.find(nil))' do
    # adherent_id nullable en base : le job fait User.find(intervention.adherent_id) sans
    # garde → User.find(nil) lève RecordNotFound, aucun mail n'est envoyé.
    @intervention.update_column(:adherent_id, nil)

    assert_no_emails do
      assert_raises(ActiveRecord::RecordNotFound) do
        NotifMailAdherentInterventionPointageJob.perform_now(@intervention)
      end
    end
  end
end
