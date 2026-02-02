require "test_helper"

class ManagerSupportMailboxTest < ActionMailbox::TestCase
  test "Créer une intervention quand un manager envoie un mail au support" do
    user = users(:hidalgo)
    subject = "Dératiser ma ville"
    body = "Bonjour, serait-il possible de dératiser Paris, tout le monde s'en plaint"
    receive_inbound_email_from_mail(to: "support@mg.coopcom.fr", from: user.email, subject: subject, body: body)

    intervention = Intervention.last
    assert_equal "[MAIL] #{subject}", intervention.description
    assert_equal "De #{user.nom_prenom_role} : #{body}", intervention.commentaires
  end
end