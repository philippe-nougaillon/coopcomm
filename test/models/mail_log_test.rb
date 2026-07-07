# frozen_string_literal: true

require 'test_helper'

class MailLogTest < ActiveSupport::TestCase
  test 'peut être rattaché à une cotation' do
    cotation = cotations(:cotation_paris)
    log = mail_logs(:mail_log)

    log.update!(cotation: cotation)

    assert_equal cotation, log.reload.cotation
    assert_includes cotation.mail_logs, log
  end

  test "la cotation n'est pas obligatoire (la plupart des logs n'en ont pas)" do
    assert mail_logs(:mail_log).cotation.nil?
    assert mail_logs(:mail_log).valid?
  end

  test 'supprimer la cotation détache le log sans le détruire (nullify)' do
    cotation = cotations(:cotation_paris)
    log = mail_logs(:mail_log)
    log.update!(cotation: cotation)

    assert_no_difference -> { MailLog.count } do
      cotation.destroy
    end
    assert_nil log.reload.cotation_id
  end
end
