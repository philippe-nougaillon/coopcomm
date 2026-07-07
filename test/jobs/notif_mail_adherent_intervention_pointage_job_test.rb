# frozen_string_literal: true

require 'test_helper'

class NotifMailAdherentInterventionPointageJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    # tonte_locaux porte un adherent_id (weil) et une organisation (via service).
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil)
  end

  test 'envoie un mail de pointage à l\'adhérent et crée un MailLog tracé' do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifMailAdherentInterventionPointageJob.perform_now(@intervention)
      end
    end

    log = MailLog.order(:created_at).last
    assert_equal @adherent.email, log.to
    assert_equal 'Intervention pointage', log.subject
    assert_equal @intervention.organisation.id, log.organisation_id
    # Le job ne connaît pas d'émetteur : user_id figé à 0 (système).
    assert_equal 0, log.user_id
    assert_equal 'mail', log.channel
    assert_equal ActionMailer::Base.deliveries.last.message_id, log.message_id
  end

  test 'le destinataire est l\'adhérent résolu via adherent_id' do
    NotifMailAdherentInterventionPointageJob.perform_now(@intervention)

    assert_equal [@adherent.email], ActionMailer::Base.deliveries.last.to
  end

  test 'une intervention sans adhérent fait échouer le job (User.find(nil))' do
    # adherent_id nullable en base : le job fait User.find(intervention.adherent_id)
    # sans garde → User.find(nil) lève RecordNotFound, aucun mail n'est envoyé.
    # (Même fragilité dans NotifWhatsappAdherentInterventionPointageJob.)
    @intervention.update_column(:adherent_id, nil)

    assert_no_emails do
      assert_raises(ActiveRecord::RecordNotFound) do
        NotifMailAdherentInterventionPointageJob.perform_now(@intervention)
      end
    end
  end
end
