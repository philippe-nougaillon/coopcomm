# frozen_string_literal: true

require 'application_system_test_case'

# Seul parcours où l'utilisateur n'est pas connecté au départ : l'invité n'a pas
# encore de mot de passe, le lien reçu par mail est sa seule porte d'entrée.
class AdherentFlowOnInvitationsTest < ApplicationSystemTestCase
  setup do
    @adherent = User.invite!(
      { nom: 'Weiss', email: 'nathalie.weiss@ville-paris.fr', rôle: 'adhérent',
        address: '12 rue de Rivoli, Paris', latitude: 48.8566, longitude: 2.3522,
        service_ids: [services(:technique).id] },
      users(:administrateur_paris)
    )
  end

  test "En tant qu'adhérent invité, je veux ouvrir le lien reçu par mail pour arriver sur la création de mon mot de passe" do
    visit lien_du_mail_d_invitation

    assert_selector 'h1', text: 'Définissez votre mot de passe'
    assert_field 'user_password'
    assert_field 'user_password_confirmation'
  end

  test "En tant qu'adhérent invité, je veux définir mon mot de passe pour accéder à l'application" do
    visit lien_du_mail_d_invitation

    fill_in 'user_password', with: 'Rivoli-2026!parisXY'
    fill_in 'user_password_confirmation', with: 'Rivoli-2026!parisXY'
    cliquer_bouton 'Définir mon mot de passe'

    assert_notification 'Votre mot de passe a été défini avec succès. Vous êtes maintenant connecté.'
    assert_current_path root_path
    assert @adherent.reload.invitation_accepted_at, "l'invitation n'a pas été acceptée"
  end

  test "En tant qu'adhérent invité, je ne peux pas enregistrer avec un mot de passe incorrect" do
    visit lien_du_mail_d_invitation

    fill_in 'user_password', with: 'abcd'
    fill_in 'user_password_confirmation', with: 'abcd'
    cliquer_bouton 'Définir mon mot de passe'

    find_error_form

    @adherent.reload
    assert_nil @adherent.invitation_accepted_at
    assert_not_equal @adherent.password, 'abcd'
  end

  test "En tant qu'adhérent invité, je ne peux pas enregistrer sans saisir mon mot de passe" do
    visit lien_du_mail_d_invitation

    fill_in 'user_password', with: ''
    fill_in 'user_password_confirmation', with: ''
    cliquer_bouton 'Définir mon mot de passe'

    @adherent.reload
    assert_nil @adherent.invitation_accepted_at
    assert_not_equal @adherent.password, ''
  end

  private

  # Le lien est lu dans le mail réellement envoyé ; seul son hôte est remplacé,
  # le mail portant celui de la configuration et non le serveur du test.
  def lien_du_mail_d_invitation
    mail = ActionMailer::Base.deliveries.last
    corps = mail.parts.map { |part| part.body.decoded }.join("\n")
    lien = corps[%r{https?://\S+/users/invitation/accept\?invitation_token=[^"&\s]+}]
    assert lien, "aucun lien d'acceptation dans le mail d'invitation"

    URI.parse(lien).request_uri
  end
end
