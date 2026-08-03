# frozen_string_literal: true

require 'test_helper'

class NotifAgentAbsenceJobTest < ActiveJob::TestCase
  setup do
    @agent = users(:bond)
    @manager = users(:hidalgo)
    @resume = { 'du' => Date.new(2030, 4, 2), 'au' => Date.new(2030, 4, 2), 'période' => 'Matin',
                'motif' => 'Formation', 'observation' => nil }
    ActionMailer::Base.deliveries.clear
  end

  test 'envoie le mail à la personne concernée et trace le MailLog' do
    assert_difference -> { ActionMailer::Base.deliveries.size } => 1, -> { MailLog.count } => 1 do
      NotifAgentAbsenceJob.perform_now('créée', @resume, nil, @agent.email,
                                       @agent.organisation.id, @manager.id)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@agent.email], mail.to
    assert_equal '[COOPCOMM] Absence créée', mail.subject
    assert_match 'Matin', mail.body.to_s
    assert_match 'Formation', mail.body.to_s
    assert_match 'Aucune', mail.body.to_s

    log = MailLog.order(:created_at).last
    assert_equal @agent.email, log.to
    assert_equal 'Absence créée', log.subject
    assert_equal @manager.id, log.user_id
  end

  test 'le mail de modification montre l’ancienne et la nouvelle valeur' do
    avant = @resume.merge('période' => 'Journée entière', 'motif' => 'Congés payés')

    NotifAgentAbsenceJob.perform_now('modifiée', @resume, avant, @agent.email,
                                     @agent.organisation.id, @manager.id)

    corps = ActionMailer::Base.deliveries.last.body.to_s

    assert_match 'Journée entière', corps
    assert_match 'Matin', corps
    assert_match 'Congés payés', corps
    assert_match 'Formation', corps
  end

  test 'sans auteur identifié le MailLog est tracé au compte système' do
    NotifAgentAbsenceJob.perform_now('supprimée', @resume, nil, @agent.email,
                                     @agent.organisation.id, nil)

    assert_equal 0, MailLog.order(:created_at).last.user_id
  end
end
