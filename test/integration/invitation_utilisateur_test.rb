# frozen_string_literal: true

require 'test_helper'

# Un compte créé par un administrateur naît sans mot de passe connu de personne :
# le mail d'invitation est le seul chemin d'entrée de l'utilisateur.
class InvitationUtilisateurTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:administrateur_paris)
    sign_in @admin
  end

  # ==================== TESTS CRITIQUES ====================
  # Sans ce mail, ou avec un lien qui ne porte pas le bon jeton, le compte créé
  # est inaccessible à son destinataire.

  test "création d'un utilisateur → un mail d'invitation part vers lui (critique)" do
    assert_emails 1 do
      créer_adherent
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal ['nathalie.weiss@ville-paris.fr'], mail.to
    assert_equal 'Vous avez reçu une invitation', mail.subject
  end

  test "le mail porte le lien d'acceptation et son jeton (critique)" do
    adherent_créé = créer_adherent

    jeton = jeton_invitation(ActionMailer::Base.deliveries.last)
    assert jeton, "le mail ne contient pas de lien vers #{accept_user_invitation_path}"
    assert_equal adherent_créé, User.find_by_invitation_token(jeton, true)
  end

  # ==================== /TESTS CRITIQUES ====================

  test "l'envoi de l'invitation est tracé dans un mail log" do
    adherent_créé = nil
    assert_difference 'MailLog.count', 1 do
      adherent_créé = créer_adherent
    end

    trace = MailLog.last
    assert_equal adherent_créé.email, trace.to
    assert_equal @admin.id, trace.user_id
    assert_equal @admin.organisation, trace.organisation
  end

  test "renvoyer l'invitation depuis la fiche → un nouveau mail part" do
    adherent_créé = créer_adherent

    assert_emails 1 do
      post inviter_user_url(adherent_créé)
    end

    assert_equal [adherent_créé.email], ActionMailer::Base.deliveries.last.to
  end

  private

  def créer_adherent
    post admin_create_new_user_do_url, params: {
      user: { nom: 'Weiss', email: 'nathalie.weiss@ville-paris.fr', rôle: 'adhérent',
              address: '12 rue de Rivoli, Paris', latitude: 48.8566, longitude: 2.3522,
              service_ids: [services(:technique).id] }
    }

    User.find_by(email: 'nathalie.weiss@ville-paris.fr')
  end

  # Le jeton en clair ne vit que dans le mail : la colonne en base est un condensat.
  # `mail.body` est vide sur un envoi multipart, d'où la lecture partie par partie.
  def jeton_invitation(mail)
    corps = mail.parts.map { |part| part.body.decoded }.join("\n")
    corps[/#{Regexp.escape(accept_user_invitation_url)}\?invitation_token=([^"&\s]+)/, 1]
  end
end
