require "test_helper"

class AdherentSupportMailboxTest < ActionMailbox::TestCase
  test "Créer une intervention quand un adhérent envoie un mail au support" do
    user = users(:weil)
    subject = "Gestion de paperasse"
    body = "Bonjour, j'ai besoin d'aide du côté administratif"
    receive_inbound_email_from_mail(to: "support@mg.coopcom.fr", from: user.email, subject: subject, body: body)

    intervention = Intervention.last
    assert_equal user.id, intervention.adherent_id
    assert_equal "[MAIL] #{subject}", intervention.description
    assert_equal "De #{user.nom_prenom_role} : #{body}", intervention.commentaires
  end
end