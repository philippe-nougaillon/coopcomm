require "test_helper"

class AdherentMailLogPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)
    
    mail_log = mail_logs(:mail_log)

    @policy = MailLogPolicy.new(adherent_paris, mail_log)
  end

  # Index
  test "accès adhérent document index interdit" do
    refute @policy.index?
  end

  # Show
  test "accès adhérent document show interdit" do
    refute @policy.show?
  end

  # Refresh
  test "accès adhérent document refresh interdit" do
    refute @policy.refresh?
  end
end
