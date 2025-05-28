require "test_helper"

class EquipeSupportMailboxTest < ActionMailbox::TestCase
  test "Ne pas créer d'intervention quand une équipe envoie un mail au support" do
    user = users(:nettoyage)
    subject = "Besoin de nettoyant"
    body = "Bonjour, j'ai besoin de nettoyant"
    assert_no_changes -> { Intervention.count } do 
      receive_inbound_email_from_mail(
        to: "support@mg.coopcom.fr",
        from: user.email,
        subject: subject,
        body: body)
    end
  end
end