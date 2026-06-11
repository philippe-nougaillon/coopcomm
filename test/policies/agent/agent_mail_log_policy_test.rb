# frozen_string_literal: true

require 'test_helper'

class AdherentMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(agent_paris, mail_log)
  end

  # Index
  test 'accès agent document index interdit' do
    refute @policy.index?
  end

  # Show
  test 'accès agent document show interdit' do
    refute @policy.show?
  end

  # Refresh
  test 'accès agent document refresh interdit' do
    refute @policy.refresh?
  end
end
