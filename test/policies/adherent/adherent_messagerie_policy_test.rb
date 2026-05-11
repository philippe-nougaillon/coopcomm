require "test_helper"

class AdherentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:patrick_adherent_paris)
    
    interlocutor_user = users(:bond)

    @policy = MessageriePolicy.new(adherent, interlocutor_user)
  end

  # Messagerie
  test "accès autorisé pour un adherent sur la page index de messagerie" do
    assert @policy.index?
  end

  # Send notification
  test "accès autorisé pour un adherent sur la page send_notification de messagerie" do
    assert @policy.send_notification?
  end

  # Search contact
  test "accès autorisé pour un adherent sur la page search_contact de messagerie" do
    assert @policy.search_contact?
  end

  # Mark as read
  test "accès autorisé pour un adherent sur la page mark_as_read de messagerie" do
    assert @policy.mark_as_read?
  end
end
