# frozen_string_literal: true

require 'test_helper'

class ManagerMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(manager, mail_log)
  end

  test 'accès autorisé pour un manager sur un mail_log de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.refresh?
  end
end
