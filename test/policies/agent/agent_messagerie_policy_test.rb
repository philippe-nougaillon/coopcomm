require "test_helper"

class AgentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:bond)
    
    interlocutor_user = users(:martin_technique_paris)

    @policy = MessageriePolicy.new(agent, interlocutor_user)
  end

  # Messagerie
  test "accès autorisé pour un agent sur la page index de messagerie" do
    assert @policy.index?
  end

  # Send notification
  test "accès autorisé pour un agent sur la page send_notification de messagerie" do
    assert @policy.send_notification?
  end

  # Search contact
  test "accès autorisé pour un agent sur la page search_contact de messagerie" do
    assert @policy.search_contact?
  end

  # Mark as read
  test "accès autorisé pour un agent sur la page mark_as_read de messagerie" do
    assert @policy.mark_as_read?
  end
end
