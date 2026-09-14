# frozen_string_literal: true

require 'test_helper'

class AdministrateurMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(administrateur, mail_log)
  end

  test 'accès autorisé pour un administrateur sur un mail_log de son organisation' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.refresh?
  end
end
