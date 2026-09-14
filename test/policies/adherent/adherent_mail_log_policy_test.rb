# frozen_string_literal: true

require 'test_helper'

class AdherentMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(adherent, mail_log)
  end

  test 'accès interdit pour un adhérent sur un mail_log de son organisation' do
    refute @policy.index?
    refute @policy.show?
    refute @policy.refresh?
  end
end
