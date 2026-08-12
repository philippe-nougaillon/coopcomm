# frozen_string_literal: true

require 'test_helper'

class AgentMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(agent, mail_log)
  end

  test 'accès interdit pour un agent sur un mail_log de son organisation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.refresh?
  end
end
