# frozen_string_literal: true

require 'test_helper'

class AdministrateurMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)

    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(administrateur_paris, mail_log)
  end

  # Index
  test "accès autorisé pour un agent pour l'index de document" do
    assert @policy.index?
  end

  # Show
  test "accès autorisé pour un agent pour le show d'un document" do
    assert @policy.show?
  end

  # Refresh
  test "accès autorisé pour un agent pour le refresh d'un document" do
    assert @policy.refresh?
  end
end
