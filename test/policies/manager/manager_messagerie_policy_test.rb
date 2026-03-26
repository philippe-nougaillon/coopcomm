require "test_helper"

class ManagerMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)
    
    interlocutor_user = users(:martin_technique_paris)

    @policy = MessageriePolicy.new(manager, interlocutor_user)
  end

  # Messagerie
  test "accès autorisé pour un agent sur la page de messagerie" do
    assert @policy.messagerie?
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
