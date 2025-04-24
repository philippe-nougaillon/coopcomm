require "test_helper"

class ManagerMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)
    
    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(manager_paris, mail_log)
  end

  # Index
  test "accès agent document index autorisé" do
    assert @policy.index?
  end

  # Show
  test "accès agent document show autorisé" do
    assert @policy.show?
  end

  # Refresh
  test "accès agent document refresh autorisé" do
    assert @policy.refresh?
  end
end
